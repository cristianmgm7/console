import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// HTTP service for downloading files from authenticated stream URLs
@LazySingleton()
class DownloadHttpService {
  DownloadHttpService(this._authenticatedHttpService, this._logger);

  final AuthenticatedHttpService _authenticatedHttpService;
  final Logger _logger;

  /// Downloads file bytes from authenticated stream URLs
  /// Returns bytes and Content-Type header
  Future<DownloadResponse> downloadFile(String url) async {
    try {
      _logger.d('Downloading audio from: ${url.contains('.m3u8') ? 'streaming URL (.m3u8)' : 'direct URL (.mp3)'}');

      // Use authenticated HTTP for API stream URLs
      _logger.d('Making authenticated GET request to: $url');
      final response = await _authenticatedHttpService.get(url);
      _logger.d('Authenticated response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        _logger.i('Downloaded file (${response.bodyBytes.length} bytes, type: $contentType)');

        return DownloadResponse(
          bytes: response.bodyBytes,
          contentType: contentType,
        );
      } else {
        _logger.e('Failed to download file: ${response.statusCode}, body: ${response.body}, headers: ${response.headers}');
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
