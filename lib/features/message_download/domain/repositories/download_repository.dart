import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';

/// Repository interface for download operations (file operations only)
abstract class DownloadRepository {
  /// Saves a transcript text file and returns the result
  Future<Result<DownloadResult>> saveTranscript(String messageId, String transcriptText, String fileName);

  /// Saves an audio file from bytes and returns the result
  Future<Result<DownloadResult>> saveAudioFile(String messageId, List<int> audioBytes, String fileName, String? contentType);

  /// Checks if the downloads directory is accessible
  Future<Result<String>> getDownloadDirectory();
}
