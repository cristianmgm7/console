import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';

/// Repository interface for download operations
abstract class DownloadRepository {
  /// Downloads a single item (audio or transcript) and returns the result
  Future<Result<DownloadResult>> downloadItem(DownloadItem item);

  /// Checks if the downloads directory is accessible
  Future<Result<String>> getDownloadDirectory();
}
