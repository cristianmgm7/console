import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:logger/logger.dart';
import 'package:universal_html/html.dart' as html;

class WebFileSaver implements FileSaver {
  WebFileSaver(this._logger);

  final Logger _logger;

  @override
  Future<Result<String>> getDownloadsDirectory() async {
    // Web doesn't have a downloads directory concept
    // Browser handles the location automatically
    return success('browser-managed');
  }

  @override
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.Url.revokeObjectUrl(url);

      _logger.i('Triggered browser download: $fileName (${bytes.length} bytes)');
      return success('browser-download:$fileName');
    } on Exception catch (e, stack) {
      _logger.e('Failed to trigger browser download: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to download file: $e'));
    }
  }

  @override
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  }) async {
    try {
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.Url.revokeObjectUrl(url);

      _logger.i('Triggered browser download: $fileName (${content.length} characters)');
      return success('browser-download:$fileName');
    } on Exception catch (e, stack) {
      _logger.e('Failed to trigger browser text download: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to download text file: $e'));
    }
  }
}
