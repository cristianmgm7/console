import 'package:equatable/equatable.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start downloading messages
class StartDownload extends DownloadEvent {
  const StartDownload(this.messageIds);

  final Set<String> messageIds;

  @override
  List<Object?> get props => [messageIds];
}

/// Event to cancel ongoing download
class CancelDownload extends DownloadEvent {
  const CancelDownload();
}

/// Internal event to update progress after each file completes
class _UpdateProgress extends DownloadEvent {
  const _UpdateProgress({
    required this.currentIndex,
    required this.totalCount,
    required this.result,
  });

  final int currentIndex;
  final int totalCount;
  final dynamic result; // DownloadResult

  @override
  List<Object?> get props => [currentIndex, totalCount, result];
}
