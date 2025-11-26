import 'package:carbon_voice_console/features/message_download/domain/usecases/download_messages_usecase.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc(
    this._downloadMessagesUsecase,
    this._logger,
  ) : super(const DownloadInitial()) {
    on<StartDownload>(_onStartDownload);
    on<CancelDownload>(_onCancelDownload);
  }

  final DownloadMessagesUsecase _downloadMessagesUsecase;
  final Logger _logger;

  bool _isCancelled = false;

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _isCancelled = false;

    final result = await _downloadMessagesUsecase(
      messageIds: event.messageIds.toList(),
      downloadType: event.downloadType,
      onProgress: (progress) {
        emit(DownloadInProgress(
          current: progress.current,
          total: progress.total,
          progressPercent: progress.progressPercent,
          currentMessageId: progress.currentMessageId,
        ),);
      },
      isCancelled: () => _isCancelled,
    );

    result.fold(
      onSuccess: (summary) {
        emit(DownloadCompleted(
          successCount: summary.successCount,
          failureCount: summary.failureCount,
          skippedCount: summary.skippedCount,
          results: summary.results,
        ),);
      },
      onFailure: (failure) {
        // Check if it was a cancellation
        if (failure.failure.code == 'UNKNOWN_ERROR' &&
            (failure.failure.details?.contains('cancelled') ?? false)) {
          // Extract item count from details if possible
          emit(const DownloadCancelled(
            completedCount: 0,
            totalCount: 0,
          ),);
        } else {
          emit(DownloadError(
            failure.failure.details ?? 'Download failed',
          ),);
        }
      },
    );
  }

  Future<void> _onCancelDownload(
    CancelDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _logger.i('Download cancellation requested');
    _isCancelled = true;
    // The actual cancellation happens in the use case
  }
}
