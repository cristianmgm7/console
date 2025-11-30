import 'dart:math';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_progress.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_summary.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadAudioMessagesUsecase {
  const DownloadAudioMessagesUsecase(
    this._downloadRepository,
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final DownloadRepository _downloadRepository;
  final Logger _logger;

  /// Downloads audio files for the specified messages
  ///
  /// [messageIds] - List of message IDs to download audio for
  /// [onProgress] - Callback for progress updates
  /// [isCancelled] - Function to check if operation has been cancelled
  ///
  /// Returns a Result containing DownloadSummary on success or Failure on error
  Future<Result<DownloadSummary>> call({
    required List<String> messageIds,
    required void Function(DownloadProgress) onProgress,
    required bool Function() isCancelled,
  }) async {
    // Validate non-empty selection
    if (messageIds.isEmpty) {
      _logger.w('Audio download started with empty message selection');
      return failure(const UnknownFailure(
        details: 'No messages selected',
      ),);
    }
    final results = <DownloadResult>[];
    final skippedMessages = <String>[];

    // Fetch metadata for all messages in parallel
    _logger.d('Fetching metadata for ${messageIds.length} messages');
    final metadataFutures = messageIds.map((messageId) => _messageRepository.getMessage(messageId, includePreSignedUrls: true));

    // Wrap Future.wait in try-catch to handle any unexpected exceptions
    late final List<Result<Message>> metadataResults;
    try {
      metadataResults = await Future.wait(metadataFutures);
    } on Exception catch (e, stack) {
      _logger.e('Unexpected error during parallel message fetching', error: e, stackTrace: stack);
      return failure(UnknownFailure(
        details: 'Failed to fetch message metadata: $e',
      ),);
    }

    // Process metadata and download audio files sequentially
    var messageIndex = 0;
    final totalItems = metadataResults.length;

    for (final result in metadataResults) {
      final messageId = messageIds.elementAt(messageIndex);
      messageIndex++;

      // Check for cancellation
      if (isCancelled()) {
        _logger.i('Audio download cancelled by user at item $messageIndex/$totalItems');
        return failure(UnknownFailure(
          details: 'Audio download cancelled at item $messageIndex of $totalItems',
        ),);
      }

      // Emit progress update
      onProgress(DownloadProgress(
        current: messageIndex,
        total: totalItems,
        currentMessageId: messageId,
      ),);

      _logger.d('🔄 Processing message $messageIndex/$totalItems: $messageId');

      if (result.isSuccess) {
        final message = result.valueOrNull!;

        // Check if message has audio with presigned URL
        final hasAudio = message.audioModels.isNotEmpty;
        final presignedUrl = hasAudio ? message.audioModels.first.presignedUrl : null;

        _logger.d('📋 Message ${message.id} hasAudio: $hasAudio, hasPresignedUrl: ${presignedUrl != null}');

        if (hasAudio && presignedUrl != null && presignedUrl.isNotEmpty) {
          _logger.i('🎵 Downloading audio for message ${message.id}');
          try {
            // Presigned URLs already contain authentication in the URL params
            // No need for Bearer token - use plain HTTP client
            final response = await http.get(Uri.parse(presignedUrl));
            _logger.i('📡 Response status: ${response.statusCode}');

            // Process the response and save file
            await _processDownloadResponse(response, message.id, results);
          } on NetworkException catch (e) {
            _logger.e('Network error downloading audio for message ${message.id}', error: e);
            results.add(DownloadResult(
              messageId: message.id,
              status: DownloadStatus.failed,
              errorMessage: 'Network error: ${e.message}',
            ),);
          } on ServerException catch (e) {
            _logger.e('Server error downloading audio for message ${message.id}', error: e);
            results.add(DownloadResult(
              messageId: message.id,
              status: DownloadStatus.failed,
              errorMessage: 'Server error: ${e.message}',
            ),);
          } on Exception catch (e, stack) {
            _logger.e('Error downloading audio for message ${message.id}', error: e, stackTrace: stack);
            results.add(DownloadResult(
              messageId: message.id,
              status: DownloadStatus.failed,
              errorMessage: e.toString(),
            ),);
          }
        } else {
          _logger.w('⏭️ Skipping message ${message.id} - no audio or presigned URL');
          results.add(DownloadResult(
            messageId: message.id,
            status: DownloadStatus.skipped,
          ),);
        }
      } else {
        _logger.e('❌ Failed to fetch metadata for message $messageId: ${result.failureOrNull}');
        results.add(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Failed to fetch message metadata',
        ),);
      }
    }

    // Add skipped messages to results
    results.addAll(skippedMessages.map((id) => DownloadResult(
      messageId: id,
      status: DownloadStatus.skipped,
    ),).toList(),);

    // Calculate final counts
    final successCount = results.where((r) => r.status == DownloadStatus.success).length;
    final failureCount = results.where((r) => r.status == DownloadStatus.failed).length;
    final skippedCount = results.where((r) => r.status == DownloadStatus.skipped).length;

    _logger.i('Audio download completed: $successCount success, $failureCount failed, $skippedCount skipped');

    return success(DownloadSummary(
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      results: results,
    ),);
  }

  /// Process download response and save the file
  Future<void> _processDownloadResponse(http.Response response, String messageId, List<DownloadResult> results) async {
    _logger.i('📡 Response status: ${response.statusCode}');

    // Check if response contains JSON (indicates API response, not audio data)
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final firstBytes = response.bodyBytes.sublist(0, min(10, response.bodyBytes.length));
      final isJson = firstBytes.length >= 2 &&
          firstBytes[0] == 0x7B && // '{'
          firstBytes[1] == 0x22;   // '"'

      if (isJson) {
        _logger.e('❌ Server returned JSON instead of audio binary data!');
        _logger.e('📄 JSON response: ${String.fromCharCodes(response.bodyBytes.take(200))}');
        results.add(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Server returned JSON metadata instead of audio data',
        ),);
        return;
      }
    }

    if (response.statusCode != 200) {
      _logger.e('❌ Download failed - Status: ${response.statusCode}');
      results.add(DownloadResult(
        messageId: messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Failed to download file (HTTP ${response.statusCode})',
      ),);
      return;
    }

    if (response.bodyBytes.isEmpty) {
      _logger.e('❌ Downloaded audio data is empty!');
      results.add(DownloadResult(
        messageId: messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Downloaded audio data is empty',
      ),);
      return;
    }

    _logger.i('✅ Downloaded ${response.bodyBytes.length} bytes');

    final contentType = response.headers['content-type'];

    // Save file using repository
    final saveResult = await _downloadRepository.saveAudioFile(
      messageId,
      response.bodyBytes,
      '$messageId.mp3',
      contentType,
    );

    saveResult.fold(
      onSuccess: (result) {
        _logger.i('💾 File saved successfully: ${result.filePath}');
        results.add(result);
      },
      onFailure: (failure) {
        results.add(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
        ),);
        _logger.e('❌ Failed to save audio file for message $messageId: ${failure.failureOrNull?.details}');
      },
    );
  }
}
