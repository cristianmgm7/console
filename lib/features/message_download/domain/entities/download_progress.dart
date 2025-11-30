import 'package:equatable/equatable.dart';

/// Represents the progress of an ongoing download operation
class DownloadProgress extends Equatable {
  const DownloadProgress({
    required this.current,
    required this.total,
    required this.currentMessageId,
  });

  final int current;
  final int total;
  final String currentMessageId;

  double get progressPercent => (current / total) * 100;

  @override
  List<Object?> get props => [current, total, currentMessageId];
}
