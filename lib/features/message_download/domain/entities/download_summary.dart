import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:equatable/equatable.dart';

/// Summary of a completed download operation
class DownloadSummary extends Equatable {
  const DownloadSummary({
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    required this.results,
  });

  final int successCount;
  final int failureCount;
  final int skippedCount;
  final List<DownloadResult> results;

  int get totalCount => successCount + failureCount + skippedCount;

  @override
  List<Object?> get props => [successCount, failureCount, skippedCount, results];
}
