import 'package:equatable/equatable.dart';

/// Result of a single file download operation
class DownloadResult extends Equatable {
  const DownloadResult({
    required this.messageId,
    required this.status,
    this.filePath,
    this.errorMessage,
  });

  final String messageId;
  final DownloadStatus status;
  final String? filePath;
  final String? errorMessage;

  @override
  List<Object?> get props => [messageId, status, filePath, errorMessage];
}

enum DownloadStatus {
  success,
  failed,
  skipped,
}
