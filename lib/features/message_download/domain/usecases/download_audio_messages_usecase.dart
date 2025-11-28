import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
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
    this._authenticatedHttpService,
    this._messageRepository,
    this._oauthRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final DownloadRepository _downloadRepository;
  final AuthenticatedHttpService _authenticatedHttpService;
  final OAuthRepository _oauthRepository;
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

      if (result.isSuccess) {
        final message = result.valueOrNull!;
        final uiMessage = message.toUiModel();

        // Check if message has playable MP3 audio
        if (uiMessage.hasPlayableAudio) {
          try {
            // Extract audio ID from the audio URL
            final audioId = _extractAudioIdFromUrl(uiMessage.audioUrl!);
            if (audioId == null || audioId.isEmpty) {
              _logger.w('Message ${uiMessage.id} has MP3 audio but could not extract audio ID from URL: ${uiMessage.audioUrl}');
              results.add(DownloadResult(
                messageId: uiMessage.id,
                status: DownloadStatus.failed,
                errorMessage: 'Could not extract audio ID from URL',
              ),);
              continue;
            }

            _logger.d('Extracted audio ID "$audioId" from URL "${uiMessage.audioUrl}" for message ${uiMessage.id}');

            // Get access token for S3 request
            final clientResult = await _oauthRepository.getClient();
            final accessToken = clientResult.fold(
              onSuccess: (client) => client?.credentials.accessToken,
              onFailure: (_) => null,
            );

            if (accessToken == null || accessToken.isEmpty) {
              _logger.w('No access token available for audio download');
              results.add(DownloadResult(
                messageId: uiMessage.id,
                status: DownloadStatus.failed,
                errorMessage: 'No access token available',
              ),);
              continue;
            }

            // Build full URL: https://api.carbonvoice.app/stream/{message_id}/{audio_id}/{file}?pxtoken={token}
            final fullUrl = '${OAuthConfig.apiBaseUrl}/stream/${uiMessage.id}/$audioId/audio.mp3?pxtoken=$accessToken';
            _logger.i('Built full URL with token: $fullUrl');

            // Download file bytes using authenticated HTTP service
            final response = await _authenticatedHttpService.get(fullUrl);

            _logger.i('🔥 AUDIO DOWNLOAD RESPONSE: Status ${response.statusCode}');
            _logger.d('Response headers: ${response.headers}');
            _logger.d('Response body length: ${response.bodyBytes.length}');

            if (response.statusCode != 200) {
              _logger.e('❌ AUDIO REQUEST FAILED - Status: ${response.statusCode}');
              _logger.e('❌ Failed URL: $fullUrl');
              _logger.e('❌ Response body: ${response.body}');
            } else {
              _logger.i('✅ AUDIO DOWNLOAD SUCCESS - Got ${response.bodyBytes.length} bytes');
            }

            if (response.statusCode == 200) {
              final contentType = response.headers['content-type'];
              _logger.i('Downloaded file (${response.bodyBytes.length} bytes, type: $contentType)');

              // Save file using repository
              final saveResult = await _downloadRepository.saveAudioFile(
                uiMessage.id,
                response.bodyBytes,
                '${uiMessage.id}.mp3',
                contentType,
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
            } else {
              _logger.e('Failed to download file: ${response.statusCode}');
              results.add(DownloadResult(
                messageId: uiMessage.id,
                status: DownloadStatus.failed,
                errorMessage: 'Failed to download file (HTTP ${response.statusCode})',
              ),);
            }
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

  /// Extract audio ID from audio URL
  /// URL pattern: .../stream/{message_id}/{audio_id}/audio.mp3
  String? _extractAudioIdFromUrl(String audioUrl) {
    try {
      final uri = Uri.parse(audioUrl);
      final pathSegments = uri.pathSegments;

      // Path should be: ['stream', '{message_id}', '{audio_id}', 'audio.mp3']
      // We want the third segment (index 2) which is the audio_id
      if (pathSegments.length >= 4 &&
          pathSegments[0] == 'stream' &&
          pathSegments[3] == 'audio.mp3') {
        return pathSegments[2];
      }

      _logger.w('Unexpected URL format for audio extraction: $audioUrl');
      return null;
    } catch (e, stack) {
      _logger.e('Failed to parse audio URL: $audioUrl', error: e, stackTrace: stack);
      return null;
    }
  }
}
