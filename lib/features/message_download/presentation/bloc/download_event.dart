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
