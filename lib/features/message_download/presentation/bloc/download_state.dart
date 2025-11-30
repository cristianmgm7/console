import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:equatable/equatable.dart';

sealed class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any download starts
class DownloadInitial extends DownloadState {
  const DownloadInitial();
}

/// Download in progress
class DownloadInProgress extends DownloadState {
  const DownloadInProgress({
    required this.current,
    required this.total,
    required this.progressPercent,
    required this.currentMessageId,
  });

  final int current;
  final int total;
  final double progressPercent;
  final String currentMessageId;

  @override
  List<Object?> get props => [current, total, progressPercent, currentMessageId];

  DownloadInProgress copyWith({
    int? current,
    int? total,
    double? progressPercent,
    String? currentMessageId,
  }) {
    return DownloadInProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      progressPercent: progressPercent ?? this.progressPercent,
      currentMessageId: currentMessageId ?? this.currentMessageId,
    );
  }
}

/// Download completed (success or with errors)
class DownloadCompleted extends DownloadState {
  const DownloadCompleted({
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    required this.results,
  });

  final int successCount;
  final int failureCount;
  final int skippedCount;
  final List<DownloadResult> results;

  @override
  List<Object?> get props => [successCount, failureCount, skippedCount, results];
}

/// Download cancelled by user
class DownloadCancelled extends DownloadState {
  const DownloadCancelled({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  List<Object?> get props => [completedCount, totalCount];
}

/// Error state (e.g., empty selection, directory access failure)
class DownloadError extends DownloadState {
  const DownloadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
