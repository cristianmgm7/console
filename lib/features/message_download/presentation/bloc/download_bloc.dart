import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc(
    this._downloadRepository,
    this._messageRepository,
    this._logger,
  ) : super(const DownloadInitial()) {
    on<StartDownload>(_onStartDownload);
    on<CancelDownload>(_onCancelDownload);
  }

  final DownloadRepository _downloadRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  bool _isCancelled = false;

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _logger.d('Starting download for ${event.messageIds.length} messages');
    _isCancelled = false;

    // Validate non-empty selection
    if (event.messageIds.isEmpty) {
      _logger.w('Download started with empty message selection');
      emit(const DownloadError('No messages selected'));
      return;
    }

    // Collect all download items from all messages
    final downloadItems = <DownloadItem>[];
    final skippedMessages = <String>[];

    // Fetch metadata for all messages in parallel
    _logger.d('Fetching metadata for ${event.messageIds.length} messages');
    final metadataFutures = event.messageIds.map((id) => _messageRepository.getMessage(id));

    // Wrap Future.wait in try-catch to handle any unexpected exceptions
    late final List<Result<Message>> metadataResults;
    try {
      metadataResults = await Future.wait(metadataFutures);
    } catch (e, stack) {
      _logger.e('Unexpected error during parallel message fetching', error: e, stackTrace: stack);
      // If Future.wait fails, treat all messages as failed/skipped
      emit(DownloadError('Failed to fetch message metadata: $e'));
      return;
    }

    // Process metadata and create download items
    int messageIndex = 0;
    for (final result in metadataResults) {
      final messageId = event.messageIds.elementAt(messageIndex);
      messageIndex++;

      result.fold(
        onSuccess: (message) {
          bool hasDownloadableContent = false;

          // Add audio download item if URL exists
          if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
            downloadItems.add(DownloadItem(
              messageId: message.id,
              type: DownloadItemType.audio,
              url: message.audioUrl!,
              fileName: '${message.id}.mp3', // Extension will be corrected based on Content-Type
            ));
            hasDownloadableContent = true;
          }

          // Add transcript download item if content exists
          final transcriptContent = message.transcript ?? message.text;
          if (transcriptContent != null && transcriptContent.isNotEmpty) {
            downloadItems.add(DownloadItem(
              messageId: message.id,
              type: DownloadItemType.transcript,
              url: transcriptContent, // For transcripts, we store content in 'url' field
              fileName: '${message.id}.txt',
            ));
            hasDownloadableContent = true;
          }

          // Track messages with no downloadable content
          if (!hasDownloadableContent) {
            _logger.w('Message ${message.id} has no audio or transcript to download');
            skippedMessages.add(message.id);
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
      emit(DownloadCompleted(
        successCount: 0,
        failureCount: 0,
        skippedCount: skippedMessages.length,
        results: skippedMessages.map((id) => DownloadResult(
          messageId: id,
          status: DownloadStatus.skipped,
        )).toList(),
      ));
      return;
    }

    // Download each item sequentially
    final results = <DownloadResult>[];
    final totalItems = downloadItems.length;

    try {
      for (int i = 0; i < downloadItems.length; i++) {
        // Check for cancellation
        if (_isCancelled) {
          _logger.i('Download cancelled by user at item ${i + 1}/$totalItems');
          emit(DownloadCancelled(
            completedCount: results.length,
            totalCount: totalItems,
          ));
          return;
        }

        final item = downloadItems[i];
        final progressPercent = ((i + 1) / totalItems * 100);

        // Emit progress state
        emit(DownloadInProgress(
          current: i + 1,
          total: totalItems,
          progressPercent: progressPercent,
          currentMessageId: item.messageId,
        ));

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
          ));
          _logger.e('Failed to download item ${i + 1}/$totalItems');
        },
      );
    }
    } catch (e, stack) {
      _logger.e('Unexpected error during download process', error: e, stackTrace: stack);
      emit(DownloadError('Download failed unexpectedly: $e'));
      return;
    }

    // Add skipped messages to results
    results.addAll(skippedMessages.map((id) => DownloadResult(
      messageId: id,
      status: DownloadStatus.skipped,
    )));

    // Calculate final counts
    final successCount = results.where((r) => r.status == DownloadStatus.success).length;
    final failureCount = results.where((r) => r.status == DownloadStatus.failed).length;
    final skippedCount = results.where((r) => r.status == DownloadStatus.skipped).length;

    _logger.i('Download completed: $successCount success, $failureCount failed, $skippedCount skipped');

    emit(DownloadCompleted(
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      results: results,
    ));
  }

  Future<void> _onCancelDownload(
    CancelDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _logger.i('Download cancellation requested');
    _isCancelled = true;
    // The actual cancellation happens in the download loop
  }
}
