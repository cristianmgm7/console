import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper para manejar OAuth en desktop mediante un servidor HTTP local
class OAuthDesktopServer {

  OAuthDesktopServer({
    this.port = 3000,
    this.callbackPath = '/auth/callback',
  });
  final Logger _logger = Logger();
  HttpServer? _server;
  final int port;
  final String callbackPath;

  /// Inicia el servidor local y abre el navegador con la URL de OAuth
  /// Retorna la URL completa con el código de autorización cuando el callback es recibido
  Future<String> authenticate(String authorizationUrl) async {
    final completer = Completer<String>();

    try {
      // Intentar iniciar servidor HTTP local, con fallback a puerto alternativo
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      } catch (e) {
        _logger.w('⚠️ Port $port is busy, trying alternative ports...');
        // Intentar puertos alternativos: 3001, 8080, 9090
        final alternativePorts = [3001, 8080, 9090];
        for (final altPort in alternativePorts) {
          try {
            _server = await HttpServer.bind(InternetAddress.loopbackIPv4, altPort);
            _logger.i('✅ Using alternative port $altPort');
            break;
          } catch (_) {
            continue;
          }
        }
        if (_server == null) {
          throw Exception('Could not bind to port $port or any alternative port');
        }
      }
      
      final actualPort = _server!.port;
      _logger.i('🌐 OAuth server listening on http://localhost:$actualPort');

      // Manejar requests
      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        _logger.d('📥 Received request: ${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}');

        if (uri.path == callbackPath) {
          // Obtener la URL completa con query params
          final fullCallbackUrl = 'http://localhost:$port${uri.path}?${uri.query}';
          _logger.i('✅ OAuth callback received: $fullCallbackUrl');

          // Responder al navegador con una página de éxito
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.set('Content-Type', 'text/html; charset=utf-8')
            ..write(_getSuccessHtml());
          await request.response.close();

          // Resolver el completer con la URL completa
          completer.complete(fullCallbackUrl);

          // Cerrar el servidor después de un pequeño delay
          Future.delayed(const Duration(seconds: 1), close);
        } else {
          // Ruta no reconocida
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
          await request.response.close();
        }
      });

      // Abrir el navegador con la URL de OAuth
      _logger.i('🌐 Opening browser: $authorizationUrl');
      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $authorizationUrl');
      }

      // Esperar a que se complete la autenticación (con timeout)
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _logger.e('⏱️ OAuth timeout - no callback received in 5 minutes');
          close();
          throw TimeoutException('OAuth authentication timeout');
        },
      );
    } catch (e) {
      _logger.e('❌ OAuth server error: $e');
      close();
      rethrow;
    }
  }

  /// Cierra el servidor local
  void close() {
    _server?.close(force: true);
    _server = null;
    _logger.i('🛑 OAuth server closed');
  }

  /// HTML para mostrar cuando la autenticación es exitosa
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
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
    // Auto-cerrar después de 3 segundos
    setTimeout(() => {
      window.close();
    }, 3000);
  </script>
</body>
</html>
    ''';
  }
}
