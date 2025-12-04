import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_progress.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_summary.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadTranscriptMessagesUsecase {
  const DownloadTranscriptMessagesUsecase(
    this._downloadRepository,
    this._messageRepository,
    this._logger,
  );

  final DownloadRepository _downloadRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Downloads transcript text files for the specified messages
  ///
  /// [messageIds] - List of message IDs to download transcripts for
  /// [onProgress] - Callback for progress updates
  /// [isCancelled] - Function to check if operation has been cancelled
  ///
  /// Returns a Result containing DownloadSummary on success or Failure on error
  Future<Result<DownloadSummary>> call({
    required List<String> messageIds,
    required void Function(DownloadProgress) onProgress,
    required bool Function() isCancelled,
  }) async {
    _logger.d('Starting transcript download for ${messageIds.length} messages');

    // Validate non-empty selection
    if (messageIds.isEmpty) {
      _logger.w('Transcript download started with empty message selection');
      return failure(const UnknownFailure(
        details: 'No messages selected',
      ),);
    }

    final results = <DownloadResult>[];

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

    // Process metadata and save transcripts sequentially
    var messageIndex = 0;
    final totalItems = metadataResults.length;

    for (final result in metadataResults) {
      final messageId = messageIds.elementAt(messageIndex);
      messageIndex++;

      // Check for cancellation
      if (isCancelled()) {
        _logger.i('Transcript download cancelled by user at item $messageIndex/$totalItems');
        return failure(UnknownFailure(
          details: 'Transcript download cancelled at item $messageIndex of $totalItems',
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

        // Check if message has transcript content
        final transcriptContent = uiMessage.transcriptText ?? uiMessage.text;
        if (transcriptContent != null && transcriptContent.isNotEmpty) {
          // Save transcript for this message
          final saveResult = await _downloadRepository.saveTranscript(
            uiMessage.id,
            transcriptContent,
            '${uiMessage.id}.txt',
          );

          saveResult.fold(
            onSuccess: (result) {
              results.add(result);
              _logger.d('Saved transcript for message ${uiMessage.id}: ${result.status}');
            },
            onFailure: (failure) {
              results.add(DownloadResult(
                messageId: uiMessage.id,
                status: DownloadStatus.failed,
                errorMessage: failure.failureOrNull?.details ?? 'Unknown error',
              ),);
              _logger.e('Failed to save transcript for message ${uiMessage.id}');
            },
          );
        } else {
          _logger.w('Message ${uiMessage.id} has no transcript content');
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

    // Calculate final counts
    final successCount = results.where((r) => r.status == DownloadStatus.success).length;
    final failureCount = results.where((r) => r.status == DownloadStatus.failed).length;
    final skippedCount = results.where((r) => r.status == DownloadStatus.skipped).length;

    _logger.i('Transcript download completed: $successCount success, $failureCount failed, $skippedCount skipped');

    return success(DownloadSummary(
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      results: results,
    ),);
  }
}
