import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/services/download_http_service.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_progress.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_summary.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation/mappers/message_ui_mapper.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadAudioMessagesUsecase {
  const DownloadAudioMessagesUsecase(
    this._downloadRepository,
    this._downloadHttpService,
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final DownloadRepository _downloadRepository;
  final DownloadHttpService _downloadHttpService;
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
    _logger.d('Starting audio download for ${messageIds.length} messages');

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
    final metadataFutures = messageIds.map(_messageRepository.getMessage);

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
        _logger.i('Audio download cancelled by user at item ${messageIndex}/$totalItems');
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

      if (result.isSuccess) {
        final message = result.valueOrNull!;
        final uiMessage = message.toUiModel();

        // Check if message has audio URL
        if (uiMessage.audioUrl != null && uiMessage.audioUrl!.isNotEmpty) {
          try {
            // Download file bytes using HTTP service
            final downloadResponse = await _downloadHttpService.downloadFile(uiMessage.audioUrl!);

            // Save file using repository
            final saveResult = await _downloadRepository.saveAudioFile(
              uiMessage.id,
              downloadResponse.bytes,
              '${uiMessage.id}.mp3',
              downloadResponse.contentType,
            );

            saveResult.fold(
              onSuccess: (result) {
                results.add(result);
                _logger.d('Downloaded and saved audio for message ${uiMessage.id}: ${result.status}');
              },
              onFailure: (failure) {
                results.add(DownloadResult(
                  messageId: uiMessage.id,
                  status: DownloadStatus.failed,
                  errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
                ),);
                _logger.e('Failed to save audio for message ${uiMessage.id}');
              },
            );
          } on NetworkException catch (e) {
            _logger.e('Network error downloading audio for message ${uiMessage.id}', error: e);
            results.add(DownloadResult(
              messageId: uiMessage.id,
              status: DownloadStatus.failed,
              errorMessage: 'Network error: ${e.message}',
            ),);
          } on ServerException catch (e) {
            _logger.e('Server error downloading audio for message ${uiMessage.id}', error: e);
            results.add(DownloadResult(
              messageId: uiMessage.id,
              status: DownloadStatus.failed,
              errorMessage: 'Server error: ${e.message}',
            ),);
          } on Exception catch (e, stack) {
            _logger.e('Error downloading audio for message ${uiMessage.id}', error: e, stackTrace: stack);
            results.add(DownloadResult(
              messageId: uiMessage.id,
              status: DownloadStatus.failed,
              errorMessage: e.toString(),
            ),);
          }
        } else {
          _logger.w('Message ${uiMessage.id} has no audio URL');
          results.add(DownloadResult(
            messageId: uiMessage.id,
            status: DownloadStatus.skipped,
          ),);
        }
      } else {
        _logger.e('Failed to fetch metadata for message $messageId: ${result.failureOrNull}');
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
    ),));

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

}
