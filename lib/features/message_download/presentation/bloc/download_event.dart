import 'package:equatable/equatable.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start downloading audio files
class StartDownloadAudio extends DownloadEvent {
  const StartDownloadAudio(this.messageIds);

  final Set<String> messageIds;

  @override
  List<Object?> get props => [messageIds];
}

/// Event to start downloading transcript files
class StartDownloadTranscripts extends DownloadEvent {
  const StartDownloadTranscripts(this.messageIds);

  final Set<String> messageIds;

  @override
  List<Object?> get props => [messageIds];
}

/// Event to cancel ongoing download
class CancelDownload extends DownloadEvent {
  const CancelDownload();
}
