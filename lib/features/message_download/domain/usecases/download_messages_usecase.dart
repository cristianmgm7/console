import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
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
class DownloadMessagesUsecase {
  const DownloadMessagesUsecase(
    this._downloadRepository,
    this._messageRepository,
    this._logger,
  );

  final DownloadRepository _downloadRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Downloads messages based on the specified download type
  ///
  /// [messageIds] - List of message IDs to download
  /// [downloadType] - Type of content to download (audio, transcript, or both)
  /// [onProgress] - Callback for progress updates
  /// [isCancelled] - Function to check if operation has been cancelled
  ///
  /// Returns a Result containing DownloadSummary on success or Failure on error
  Future<Result<DownloadSummary>> call({
    required List<String> messageIds,
    required DownloadType downloadType,
    required void Function(DownloadProgress) onProgress,
    required bool Function() isCancelled,
  }) async {
    _logger.d('Starting download for ${messageIds.length} messages');

    // Validate non-empty selection
    if (messageIds.isEmpty) {
      _logger.w('Download started with empty message selection');
      return failure(const UnknownFailure(
        details: 'No messages selected',
      ),);
    }

    // Collect all download items from all messages
    final downloadItems = <DownloadItem>[];
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

    // Process metadata and create download items
    var messageIndex = 0;
    for (final result in metadataResults) {
      final messageId = messageIds.elementAt(messageIndex);
      messageIndex++;

      result.fold(
        onSuccess: (Message message) {
          final uiMessage = message.toUiModel();
          var hasDownloadableContent = false;

          // Add audio download item if URL exists and audio is requested
          if (downloadType == DownloadType.audio || downloadType == DownloadType.both) {
            if (uiMessage.audioUrl != null && uiMessage.audioUrl!.isNotEmpty) {
              downloadItems.add(DownloadItem(
                messageId: uiMessage.id,
                type: DownloadItemType.audio,
                url: uiMessage.audioUrl!,
                fileName: '${uiMessage.id}.mp3', // Extension will be corrected based on Content-Type
              ),);
              hasDownloadableContent = true;
            }
          }

          // Add transcript download item if content exists and transcript is requested
          if (downloadType == DownloadType.transcript || downloadType == DownloadType.both) {
            final transcriptContent = uiMessage.transcriptText ?? uiMessage.text;
            if (transcriptContent != null && transcriptContent.isNotEmpty) {
              downloadItems.add(DownloadItem(
                messageId: uiMessage.id,
                type: DownloadItemType.transcript,
                url: transcriptContent, // For transcripts, we store content in 'url' field
                fileName: '${uiMessage.id}.txt',
              ),);
              hasDownloadableContent = true;
            }
          }

          // Track messages with no downloadable content
          if (!hasDownloadableContent) {
            _logger.w('Message ${uiMessage.id} has no requested content to download (type: $downloadType)');
            skippedMessages.add(uiMessage.id);
          }
        },
        onFailure: (failure) {
          _logger.e('Failed to fetch metadata for message $messageId: ${failure.failureOrNull}');
          skippedMessages.add(messageId);
        },
      );
    }

    // Check if we have anything to download
    if (downloadItems.isEmpty) {
      _logger.w('No downloadable items found after metadata fetch');
      return success(DownloadSummary(
        successCount: 0,
        failureCount: 0,
        skippedCount: skippedMessages.length,
        results: skippedMessages.map((id) => DownloadResult(
          messageId: id,
          status: DownloadStatus.skipped,
        ),).toList(),
      ),);
    }

    // Download each item sequentially
    final results = <DownloadResult>[];
    final totalItems = downloadItems.length;

    try {
      for (var i = 0; i < downloadItems.length; i++) {
        // Check for cancellation
        if (isCancelled()) {
          _logger.i('Download cancelled by user at item ${i + 1}/$totalItems');
          return failure(UnknownFailure(
            details: 'Download cancelled at item ${i + 1} of $totalItems',
          ),);
        }

        final item = downloadItems[i];

        // Emit progress update
        onProgress(DownloadProgress(
          current: i + 1,
          total: totalItems,
          currentMessageId: item.messageId,
        ),);

        // Download the item
        final result = await _downloadRepository.downloadItem(item);

        result.fold(
          onSuccess: (downloadResult) {
            results.add(downloadResult);
            _logger.d('Downloaded item ${i + 1}/$totalItems: ${downloadResult.status}');
          },
          onFailure: (failure) {
            // Treat repository failures as failed downloads
            results.add(DownloadResult(
              messageId: item.messageId,
              status: DownloadStatus.failed,
              errorMessage: failure.failureOrNull?.details ?? 'Unknown error',
            ),);
            _logger.e('Failed to download item ${i + 1}/$totalItems');
          },
        );
      }
    } on Exception catch (e, stack) {
      _logger.e('Unexpected error during download process', error: e, stackTrace: stack);
      return failure(UnknownFailure(
        details: 'Download failed unexpectedly: $e',
      ),);
    }

    // Add skipped messages to results
    results.addAll(skippedMessages.map((id) => DownloadResult(
      messageId: id,
      status: DownloadStatus.skipped,
    ),),);

    // Calculate final counts
    final successCount = results.where((r) => r.status == DownloadStatus.success).length;
    final failureCount = results.where((r) => r.status == DownloadStatus.failed).length;
    final skippedCount = results.where((r) => r.status == DownloadStatus.skipped).length;

    _logger.i('Download completed: $successCount success, $failureCount failed, $skippedCount skipped');

    return success(DownloadSummary(
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      results: results,
    ),);
  }
}
