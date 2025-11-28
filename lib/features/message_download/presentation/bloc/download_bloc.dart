import 'package:carbon_voice_console/features/message_download/domain/usecases/download_audio_messages_usecase.dart';
import 'package:carbon_voice_console/features/message_download/domain/usecases/download_transcript_messages_usecase.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc(
    this._downloadAudioMessagesUsecase,
    this._downloadTranscriptMessagesUsecase,
    this._logger,
  ) : super(const DownloadInitial()) {
    on<StartDownloadAudio>(_onStartDownloadAudio);
    on<StartDownloadTranscripts>(_onStartDownloadTranscripts);
    on<CancelDownload>(_onCancelDownload);
  }

  final DownloadAudioMessagesUsecase _downloadAudioMessagesUsecase;
  final DownloadTranscriptMessagesUsecase _downloadTranscriptMessagesUsecase;
  final Logger _logger;

  bool _isCancelled = false;

  Future<void> _onStartDownloadAudio(
    StartDownloadAudio event,
    Emitter<DownloadState> emit,
  ) async {
    _isCancelled = false;

    try {
      final result = await _downloadAudioMessagesUsecase.call(
        messageIds: event.messageIds.toList(),
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
            emit(const DownloadCancelled(
              completedCount: 0,
              totalCount: 0,
            ),);
          } else {
            emit(DownloadError(
              failure.failure.details ?? 'Audio download failed',
            ),);
          }
        },
      );
    } catch (e, stack) {
      _logger.e('Unexpected error in audio download', error: e, stackTrace: stack);
      emit(DownloadError(
        'Unexpected error: ${e.toString()}',
      ),);
    }
  }

  Future<void> _onStartDownloadTranscripts(
    StartDownloadTranscripts event,
    Emitter<DownloadState> emit,
  ) async {
    _isCancelled = false;

    try {
      final result = await _downloadTranscriptMessagesUsecase.call(
        messageIds: event.messageIds.toList(),
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
          if (failure.failure.details?.contains('cancelled') ?? false) {
            emit(const DownloadCancelled(
              completedCount: 0,
              totalCount: 0,
            ),);
          } else {
            emit(DownloadError(
              failure.failure.details ?? 'Transcript download failed',
            ),);
          }
        },
      );
    } catch (e, stack) {
      _logger.e('Unexpected error in transcript download', error: e, stackTrace: stack);
      emit(DownloadError(
        'Unexpected error: ${e.toString()}',
      ),);
    }
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
