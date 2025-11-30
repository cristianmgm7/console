import 'package:carbon_voice_console/core/utils/result.dart';

/// Platform-agnostic interface for saving files
abstract class FileSaver {
  /// Gets the downloads directory path
  /// For macOS: ~/Downloads
  /// For Web: N/A (browser handles location)
  Future<Result<String>> getDownloadsDirectory();

  /// Saves binary data to a file
  /// Returns the full file path on success
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  });

  /// Saves text content to a file
  /// Returns the full file path on success
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  });
}
