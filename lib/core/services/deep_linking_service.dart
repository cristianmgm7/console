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

  // Callback to notify when a deep link is received
  void Function(String)? _onDeepLinkReceived;

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink') {
        final url = call.arguments as String?;
        if (url != null) {
          _logger.i('📱 Deep link received: $url');
          _onDeepLinkReceived?.call(url);
        }
      }
    });
  }

  /// Set a callback to be called when a deep link is received
  void setDeepLinkHandler(void Function(String) handler) {
    
    _onDeepLinkReceived = handler;
  }

  /// Clear the deep link handler
  void clearDeepLinkHandler() {
    _onDeepLinkReceived = null;
  }
}
