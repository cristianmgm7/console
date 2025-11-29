import 'dart:math';

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
            // Get access token for potential fallback request
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

            // Extract audio ID from the audio URL
            _logger.d('🔗 Audio URL: ${uiMessage.audioUrl}');
            final audioId = _extractAudioIdFromUrl(uiMessage.audioUrl!);
            _logger.d('🔍 Extracted audio ID: $audioId');

            if (audioId == null || audioId.isEmpty) {
              _logger.w('❌ Could not extract audio ID from URL: ${uiMessage.audioUrl}');
              results.add(DownloadResult(
                messageId: uiMessage.id,
                status: DownloadStatus.failed,
                errorMessage: 'Could not extract audio ID from URL',
              ),);
              continue;
            }

            // Build the stream endpoint: /stream/{message_id}/{audio_id}/{file}?pxtoken={token}
            final streamUrl = '${OAuthConfig.apiBaseUrl}/stream/${uiMessage.id}/$audioId/audio.mp3?pxtoken=$accessToken';
            _logger.i('🎵 Trying stream endpoint: $streamUrl');
            _logger.i('📝 Message ID: ${uiMessage.id}, Audio ID: $audioId');

            final response = await _authenticatedHttpService.get(streamUrl);
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
                  messageId: uiMessage.id,
                  status: DownloadStatus.failed,
                  errorMessage: 'Server returned JSON metadata instead of audio data',
                ),);
                continue;
              }
            }

            _logger.i('🔥 AUDIO DOWNLOAD RESPONSE: Status ${response.statusCode}');
            _logger.d('Response headers: ${response.headers}');
            _logger.d('Response body length: ${response.bodyBytes.length}');

            // The URL used for the final response
            final finalUrl = response.request?.url.toString() ?? streamUrl;

            if (response.statusCode != 200) {
              _logger.e('❌ AUDIO REQUEST FAILED - Status: ${response.statusCode}');
              _logger.e('❌ Failed URL: $finalUrl');
              _logger.e('❌ Response body: ${response.body}');
            } else {
              _logger.i('✅ AUDIO DOWNLOAD SUCCESS - Got ${response.bodyBytes.length} bytes from $finalUrl');
            }

            if (response.statusCode == 200) {
              final contentType = response.headers['content-type'];
              _logger.i('✅ Downloaded file (${response.bodyBytes.length} bytes, type: $contentType)');

              // Debug: Check audio data integrity
              if (response.bodyBytes.isEmpty) {
                _logger.e('❌ Downloaded audio data is empty!');
                results.add(DownloadResult(
                  messageId: uiMessage.id,
                  status: DownloadStatus.failed,
                  errorMessage: 'Downloaded audio data is empty',
                ),);
                continue;
              }

              // Check if response is actually HTML (error page) instead of audio
              final isHtml = response.bodyBytes.length > 100 &&
                  response.bodyBytes[0] == 0x3C && // '<'
                  response.bodyBytes[1] == 0x21 && // '!'
                  response.bodyBytes[2] == 0x44 && // 'D'
                  response.bodyBytes[3] == 0x4F && // 'O'
                  response.bodyBytes[4] == 0x43 && // 'C'
                  response.bodyBytes[5] == 0x54 && // 'T'
                  response.bodyBytes[6] == 0x59 && // 'Y'
                  response.bodyBytes[7] == 0x50 && // 'P'
                  response.bodyBytes[8] == 0x45;   // 'E'

              if (isHtml) {
                _logger.e('❌ Server returned HTML instead of audio! This is likely an error page.');
                _logger.e('📄 HTML preview: ${String.fromCharCodes(response.bodyBytes.sublist(0, min(200, response.bodyBytes.length)))}');
                results.add(DownloadResult(
                  messageId: uiMessage.id,
                  status: DownloadStatus.failed,
                  errorMessage: 'Server returned HTML error page instead of audio',
                ),);
                continue;
              }

              // Check for audio file signatures
              if (response.bodyBytes.length >= 12) {
                final header = response.bodyBytes.sublist(0, 12);
                _logger.d('🔍 Audio data header: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

                // Check for common audio signatures
                final isMp3 = header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33; // ID3
                final isMp3Frame = header[0] == 0xFF && (header[1] & 0xE0) == 0xE0; // MP3 frame sync
                final isWav = header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46; // RIFF

                _logger.d('🎵 Audio format detection: MP3_ID3=$isMp3, MP3_Frame=$isMp3Frame, WAV=$isWav');
              }

              // Debug: Show sample of downloaded data before saving
              if (response.bodyBytes.length > 20) {
                final sample = response.bodyBytes.sublist(0, min(20, response.bodyBytes.length));
                _logger.i('🔍 Downloaded data sample: ${sample.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

                // Check if it looks like text data instead of binary audio
                final isTextData = response.bodyBytes.length < 10000 &&
                    response.bodyBytes.every((b) => b >= 32 && b <= 126 || b == 10 || b == 13 || b == 9);
                if (isTextData) {
                  _logger.w('⚠️ Downloaded data appears to be TEXT, not binary audio!');
                  _logger.w('📄 Text content preview: ${String.fromCharCodes(response.bodyBytes.take(min(200, response.bodyBytes.length)))}');
                } else {
                  _logger.i('✅ Downloaded data appears to be binary (good for audio)');
                }
              } else if (response.bodyBytes.length <= 1000) {
                // Show complete content if it's suspiciously small for audio (should be KB or MB)
                _logger.e('🚨 CRITICAL: Downloaded data is suspiciously small for audio: ${response.bodyBytes.length} bytes');
                _logger.e('📄 Complete content: ${String.fromCharCodes(response.bodyBytes)}');
                _logger.e('🔍 Hex dump: ${response.bodyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

                // Try to parse as JSON
                try {
                  final jsonString = String.fromCharCodes(response.bodyBytes);
                  if (jsonString.trim().startsWith('{') || jsonString.trim().startsWith('[')) {
                    _logger.e('🚨 CONFIRMED: Server returned JSON instead of audio! This endpoint returns metadata, not audio data.');
                    _logger.e('📋 JSON Content: $jsonString');
                  }
                } catch (e) {
                  // Not JSON, but still suspiciously small
                  _logger.w('⚠️ Data is small but not JSON - might be a URL or other text');
                }
              }

              // Save file using repository
              final saveResult = await _downloadRepository.saveAudioFile(
                uiMessage.id,
                response.bodyBytes,
                '${uiMessage.id}.mp3',
                contentType,
              );

              saveResult.fold(
                onSuccess: (result) {
                  _logger.i('💾 File saved successfully: ${result.filePath}');
                  _logger.i('📊 Saved ${response.bodyBytes.length} bytes to ${result.filePath}');
                  _logger.i('✅ Audio download completed for message ${uiMessage.id}');
                  results.add(result);
                },
                onFailure: (failure) {
                  results.add(DownloadResult(
                    messageId: uiMessage.id,
                    status: DownloadStatus.failed,
                    errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
                  ),);
                  _logger.e('❌ Failed to save audio file for message ${uiMessage.id}: ${failure.failureOrNull?.details}');
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
