import 'dart:io';
import 'package:path/path.dart' as path;

/// Helper class for generating unique file names
class FileNameHelper {
  /// Extracts file extension from URL or Content-Type header
  /// Falls back to .mp3 if unknown
  static String getAudioExtension(String url, String? contentType) {
    // Try to get extension from URL first
    final uri = Uri.parse(url);
    final urlPath = uri.path;
    final urlExtension = path.extension(urlPath);

    if (urlExtension.isNotEmpty && urlExtension != '.') {
      return urlExtension; // Returns with leading dot (e.g., ".mp3")
    }

    // Try to get extension from Content-Type
    if (contentType != null) {
      final mimeType = contentType.split(';').first.trim().toLowerCase();
      switch (mimeType) {
        case 'audio/mpeg':
        case 'audio/mp3':
          return '.mp3';
        case 'audio/wav':
        case 'audio/wave':
          return '.wav';
        case 'audio/ogg':
          return '.ogg';
        case 'audio/webm':
          return '.webm';
        case 'audio/aac':
          return '.aac';
        case 'audio/m4a':
        case 'audio/mp4':
          return '.m4a';
        case 'audio/flac':
          return '.flac';
        default:
          return '.mp3'; // Fallback
      }
    }

    return '.mp3'; // Default fallback
  }

  /// Generates a unique file name if file already exists
  /// Appends _1, _2, etc. to avoid collisions
  static String getUniqueFileName(String directoryPath, String baseFileName) {
    final basePath = path.join(directoryPath, baseFileName);

    // If file doesn't exist, use original name
    if (!File(basePath).existsSync()) {
      return baseFileName;
    }

    // Extract name and extension
    final extension = path.extension(baseFileName);
    final nameWithoutExtension = path.basenameWithoutExtension(baseFileName);

    // Try appending _1, _2, _3, etc.
    var counter = 1;
    while (true) {
      final newFileName = '${nameWithoutExtension}_$counter$extension';
      final newPath = path.join(directoryPath, newFileName);

      if (!File(newPath).existsSync()) {
        return newFileName;
      }

      counter++;

      // Safety check to avoid infinite loop
      if (counter > 1000) {
        throw Exception('Could not generate unique file name after 1000 attempts');
      }
    }
  }

  /// Generates directory path with date: ~/Downloads/CarbonVoice/YYYY-MM-DD/
  static String getDateBasedDirectory(String baseDownloadsPath) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return path.join(baseDownloadsPath, 'CarbonVoice', dateStr);
  }
}
