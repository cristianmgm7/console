import 'package:equatable/equatable.dart';

/// Represents a single downloadable item (audio or transcript)
class DownloadItem extends Equatable {
  const DownloadItem({
    required this.messageId,
    required this.type,
    required this.url,
    required this.fileName,
  });

  final String messageId;
  final DownloadItemType type;
  final String url; // For audio, this is the signed URL. For transcript, it's the text content
  final String fileName;

  @override
  List<Object?> get props => [messageId, type, url, fileName];
}

enum DownloadItemType {
  audio,
  transcript,
}
