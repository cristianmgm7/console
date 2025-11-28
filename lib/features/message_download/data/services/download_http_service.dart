import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// HTTP service for downloading files from authenticated URLs
@LazySingleton()
class DownloadHttpService {
  DownloadHttpService(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  /// Downloads file bytes from an authenticated URL
  /// Returns bytes and Content-Type header
  Future<DownloadResponse> downloadFile(String url) async {
    try {
      _logger.d('Downloading file from: $url');

      // Use authenticated HTTP service to include OAuth token
      final response = await _httpService.get(url);

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        _logger.i('Downloaded file (${response.bodyBytes.length} bytes, type: $contentType)');

        return DownloadResponse(
          bytes: response.bodyBytes,
          contentType: contentType,
        );
      } else {
        _logger.e('Failed to download file: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to download file',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      _logger.e('Network error downloading file', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to download file: $e');
    }
  }
}

/// Response from file download
class DownloadResponse {
  const DownloadResponse({
    required this.bytes,
    this.contentType,
  });

  final List<int> bytes;
  final String? contentType;
}
