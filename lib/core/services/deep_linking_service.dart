import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service to handle deep linking (carbonvoice://) on desktop platforms
@LazySingleton()
class DeepLinkingService {
  DeepLinkingService(this._logger) {
    _setupMethodChannel();
  }

  final Logger _logger;
  static const _channel = MethodChannel('com.carbonvoice.console/deep_linking');

  // Map of URL path prefixes to their handlers (can have multiple handlers per path)
  final Map<String, List<void Function(String)>> _pathHandlers = {};

  // Fallback handler for URLs that don't match any specific path
  void Function(String)? _fallbackHandler;

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      _logger.i('📱 MethodChannel call received - method: ${call.method}, arguments: ${call.arguments}');
      if (call.method == 'handleDeepLink') {
        final url = call.arguments as String?;
        if (url != null) {
          _logger.i('📱 Deep link received: $url');
          _handleDeepLink(url);
        } else {
          _logger.w('📱 Deep link call received but URL is null');
        }
      } else {
        _logger.w('📱 Unknown method channel call: ${call.method}');
      }
    });
  }

  /// Handle incoming deep link by routing to appropriate handler
  void _handleDeepLink(String url) {
    try {
      final uri = Uri.parse(url);

      // Try to find handlers for this specific path
      for (final entry in _pathHandlers.entries) {
        if (uri.path.startsWith(entry.key)) {
          _logger.i('📱 Routing deep link to ${entry.value.length} handler(s) for path: ${entry.key}');
          // Call all handlers registered for this path - each handler decides if it should process
          for (final handler in entry.value) {
            try {
              handler(url);
            } catch (e, stackTrace) {
              _logger.e('📱 Error in deep link handler', error: e, stackTrace: stackTrace);
            }
          }
          return;
        }
      }

      // If no specific handler found, use fallback
      if (_fallbackHandler != null) {
        _logger.i('📱 Using fallback handler for deep link');
        _fallbackHandler!(url);
        return;
      }

      _logger.w('📱 No handler found for deep link: $url');
    } catch (e, stackTrace) {
      _logger.e('📱 Error handling deep link', error: e, stackTrace: stackTrace);
    }
  }

  /// Register a handler for URLs with a specific path prefix
  /// Multiple handlers can be registered for the same path - each will be called
  void setDeepLinkHandlerForPath(String pathPrefix, void Function(String) handler) {
    _logger.i('📱 Registering deep link handler for path: $pathPrefix');
    _pathHandlers.putIfAbsent(pathPrefix, () => []).add(handler);
  }

  /// Remove a handler for a specific path prefix
  /// If handler is provided, removes only that handler; otherwise removes all handlers for the path
  void removeDeepLinkHandlerForPath(String pathPrefix, [void Function(String)? handler]) {
    if (handler != null) {
      _logger.i('📱 Removing specific deep link handler for path: $pathPrefix');
      _pathHandlers[pathPrefix]?.remove(handler);
      if (_pathHandlers[pathPrefix]?.isEmpty ?? false) {
        _pathHandlers.remove(pathPrefix);
      }
    } else {
      _logger.i('📱 Removing all deep link handlers for path: $pathPrefix');
      _pathHandlers.remove(pathPrefix);
    }
  }

  /// Set a fallback handler for URLs that don't match any specific path
  /// This replaces any previous fallback handler
  void setFallbackDeepLinkHandler(void Function(String) handler) {
    _logger.i('📱 Setting fallback deep link handler');
    _fallbackHandler = handler;
  }

  /// Clear the fallback deep link handler
  void clearFallbackDeepLinkHandler() {
    _logger.i('📱 Clearing fallback deep link handler');
    _fallbackHandler = null;
  }

  /// Legacy method for backward compatibility - sets fallback handler
  @Deprecated('Use setDeepLinkHandlerForPath() for path-specific handlers or setFallbackDeepLinkHandler() for fallback handling')
  void setDeepLinkHandler(void Function(String) handler) {
    setFallbackDeepLinkHandler(handler);
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use removeDeepLinkHandlerForPath() or clearFallbackDeepLinkHandler()')
  void clearDeepLinkHandler() {
    clearFallbackDeepLinkHandler();
  }
}
