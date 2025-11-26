import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:equatable/equatable.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start downloading messages
class StartDownload extends DownloadEvent {
  const StartDownload(this.messageIds, {this.downloadType = DownloadType.both});

  final Set<String> messageIds;
  final DownloadType downloadType;

  @override
  List<Object?> get props => [messageIds, downloadType];
}

/// Event to cancel ongoing download
class CancelDownload extends DownloadEvent {
  const CancelDownload();
}
