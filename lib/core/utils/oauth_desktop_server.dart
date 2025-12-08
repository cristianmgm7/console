import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to handle OAuth on desktop through a local HTTP server
class OAuthDesktopServer {

  OAuthDesktopServer({
    this.port = 3000,
    this.callbackPath = '/auth/callback',
  });

  HttpServer? _server;
  final int port;
  final String callbackPath;

  final Logger _logger = Logger();

  /// Starts the local server and opens the browser with the OAuth URL
  /// Returns the full callback URL with the authorization code when the callback is received
  Future<String> authenticate(String authorizationUrl) async {
    final completer = Completer<String>();

    try {
      // Try to start local HTTP server, with fallback to alternative ports
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      } on SocketException catch (e) {
        _logger.e('❌ Error binding to port $port: ${e.message}');
        // Try alternative ports: 3001, 8080, 9090
        final alternativePorts = [3001, 8080, 9090];
        for (final altPort in alternativePorts) {
          try {
            _server = await HttpServer.bind(InternetAddress.loopbackIPv4, altPort);
            _logger.i('✅ Using alternative port $altPort');
            break;
          } on SocketException catch (e) {
            _logger.e('❌ Error binding to port $altPort: ${e.message}');
            continue;
          }
        }
        if (_server == null) {
          throw Exception('Could not bind to port $port or any alternative port');
        }
      }
      
      final actualPort = _server!.port;
      _logger.i('🌐 OAuth server listening on http://localhost:$actualPort');

      // Handle requests
      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        _logger.d('📥 Received request: ${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}');

        if (uri.path == callbackPath) {
          // Get the full callback URL with query params
          final fullCallbackUrl = 'http://localhost:$port${uri.path}?${uri.query}';
          _logger.i('✅ OAuth callback received: $fullCallbackUrl');

          // Respond to the browser with a success page
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.set('Content-Type', 'text/html; charset=utf-8')
            ..write(_getSuccessHtml());
          await request.response.close();

          // Complete the completer with the full callback URL
          completer.complete(fullCallbackUrl);

          // Close the server after a short delay
          Future.delayed(const Duration(seconds: 1), close);
        } else {
          // Unrecognized route
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
          await request.response.close();
        }
      });

      // Open the browser with the OAuth URL
      _logger.i('🌐 Opening browser: $authorizationUrl');
      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $authorizationUrl');
      }

      // Wait until authentication completes (with timeout)
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _logger.e('⏱️ OAuth timeout - no callback received in 5 minutes');
          unawaited(close());
          throw TimeoutException('OAuth authentication timeout');
        },
      );
    } catch (e) {
      _logger.e('❌ OAuth server error: $e');
      await close();
      rethrow;
    }
  }

  /// Close the local server
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _logger.i('🛑 OAuth server closed');
  }

  /// HTML to display when authentication is successful
  String _getSuccessHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Authentication Successful</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #E6E6FA 0%, #F3E5F5 100%);
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 10px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
      text-align: center;
      max-width: 400px;
    }
    .success-icon {
      font-size: 60px;
      margin-bottom: 20px;
    }
    h1 {
      color: #333;
      margin-bottom: 10px;
    }
    p {
      color: #666;
      line-height: 1.6;
    }
    .close-info {
      margin-top: 20px;
      font-size: 14px;
      color: #999;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="success-icon">✅</div>
    <h1>Authentication Successful!</h1>
    <p>You have successfully authenticated with Carbon Voice.</p>
    <p>You can close this window and return to the app.</p>
    <div class="close-info">This window will close automatically...</div>
  </div>
  <script>
    // Auto-close after 3 seconds
    setTimeout(() => {
      window.close();
    }, 3000);
  </script>
</body>
</html>
    ''';
  }
}
