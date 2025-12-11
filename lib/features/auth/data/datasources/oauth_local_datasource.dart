import 'dart:convert';
import 'dart:io';

import 'package:carbon_voice_console/core/web/web_stub.dart'
    if (dart.library.html) 'package:web/web.dart'
    as web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:path_provider/path_provider.dart';

abstract class OAuthLocalDataSource {
  Future<void> saveCredentials(oauth2.Credentials credentials);
  Future<oauth2.Credentials?> loadCredentials();
  Future<void> deleteCredentials();

  // Para web: guardar/recuperar el state del OAuth flow
  Future<void> saveOAuthState(String state, String codeVerifier);
  Future<Map<String, String>?> loadOAuthState(String state);
  Future<void> clearOAuthState(String state);
}

@LazySingleton(as: OAuthLocalDataSource)
class OAuthLocalDataSourceImpl implements OAuthLocalDataSource {
  OAuthLocalDataSourceImpl(this._storage);

  static const _credentialsKey = 'oauth_credentials';
  final FlutterSecureStorage _storage;

  final Logger _logger = Logger();

  @override
  Future<void> saveCredentials(oauth2.Credentials credentials) async {
    final json = credentials.toJson();

    if (kIsWeb) {
      // Use localStorage for web builds (secure storage doesn't work well with WASM)
      try {
        web.window.localStorage[_credentialsKey] = json;
        _logger.d('Credentials saved to localStorage');
      } on Exception catch (e) {
        _logger.e('Error saving credentials to localStorage', error: e);
      }
    } else {
      // Use file-based storage for desktop (works with ad-hoc signed apps)
      // Keychain access fails with error -34018 on distributed builds
      try {
        await _saveToFile(json);
        _logger.d('Credentials saved to file storage');
      } on Exception catch (e) {
        _logger.e('Error saving credentials to file', error: e);
        // Fallback to secure storage (will fail on distributed builds but worth trying)
        try {
          await _storage.write(key: _credentialsKey, value: json);
        } catch (e2) {
          _logger.e('Fallback to secure storage also failed', error: e2);
          rethrow;
        }
      }
    }
  }

  @override
  Future<oauth2.Credentials?> loadCredentials() async {
    String? jsonString;

    if (kIsWeb) {
      // Use localStorage for web builds
      try {
        jsonString = web.window.localStorage[_credentialsKey];
      } on Exception catch (e) {
        _logger.e('Error loading credentials from localStorage', error: e);
        return null;
      }
    } else {
      // Try file-based storage first (works with ad-hoc signed apps)
      try {
        jsonString = await _loadFromFile();
        if (jsonString != null) {
          _logger.d('Credentials loaded from file storage');
        }
      } on Exception catch (e) {
        _logger.w('Error loading credentials from file', error: e);
      }

      // Fallback to secure storage if file doesn't exist
      if (jsonString == null) {
        try {
          jsonString = await _storage.read(key: _credentialsKey);
          if (jsonString != null) {
            _logger.d('Credentials loaded from secure storage');
          }
        } catch (e) {
          _logger.w('Error loading credentials from secure storage', error: e);
        }
      }
    }

    if (jsonString == null) return null;
    try {
      // oauth2.Credentials.fromJson expects a JSON string representing the credentials
      return oauth2.Credentials.fromJson(jsonString);
    } on Exception catch (e) {
      _logger.e('Error parsing credentials JSON', error: e);
      // Credentials corrupted or old format
      return null;
    }
  }

  @override
  Future<void> deleteCredentials() async {
    if (kIsWeb) {
      // Use localStorage for web builds
      try {
        web.window.localStorage.removeItem(_credentialsKey);
        _logger.d('Credentials deleted from localStorage');
      } on Exception catch (e) {
        _logger.e('Error deleting credentials from localStorage', error: e);
      }
    } else {
      // Delete from both file storage and secure storage
      try {
        await _deleteFile();
        _logger.d('Credentials deleted from file storage');
      } on Exception catch (e) {
        _logger.w('Error deleting credentials from file', error: e);
      }

      try {
        await _storage.delete(key: _credentialsKey);
        _logger.d('Credentials deleted from secure storage');
      } on Exception catch (e) {
        _logger.w('Error deleting credentials from secure storage', error: e);
      }
    }
  }

  // Helper methods for file-based storage (works with ad-hoc signed apps)
  Future<String> get _credentialsFilePath async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/$_credentialsKey.dat';
  }

  Future<void> _saveToFile(String data) async {
    if (kIsWeb) return;
    final filePath = await _credentialsFilePath;
    final file = File(filePath);

    // Ensure directory exists
    await file.parent.create(recursive: true);

    // Simple obfuscation (base64) - not encryption but better than plain text
    final encoded = base64Encode(utf8.encode(data));
    await file.writeAsString(encoded);
  }

  Future<String?> _loadFromFile() async {
    if (kIsWeb) return null;
    try {
      final filePath = await _credentialsFilePath;
      final file = File(filePath);

      if (!file.existsSync()) {
        return null;
      }

      final encoded = await file.readAsString();
      final decoded = utf8.decode(base64Decode(encoded));
      return decoded;
    } on Exception catch (e) {
      _logger.e('Error reading credentials file', error: e);
      return null;
    }
  }

  Future<void> _deleteFile() async {
    if (kIsWeb) return;
    try {
      final filePath = await _credentialsFilePath;
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
      }
    } on Exception catch (e) {
      _logger.e('Error deleting credentials file', error: e);
    }
  }

  @override
  Future<void> saveOAuthState(String state, String codeVerifier) async {
    if (!kIsWeb) return;

    try {
      final data = {
        'state': state,
        'codeVerifier': codeVerifier,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      web.window.sessionStorage['oauth_state_$state'] = jsonEncode(data);
    } on Exception catch (e) {
      _logger.e('Error saving OAuth state', error: e);
    }
  }

  @override
  Future<Map<String, String>?> loadOAuthState(String state) async {
    if (!kIsWeb) return null;

    try {
      final dataStr = web.window.sessionStorage['oauth_state_$state'];
      if (dataStr == null) {
        return null;
      }

      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      return {
        'state': data['state'] as String,
        'codeVerifier': data['codeVerifier'] as String,
      };
    } on Exception catch (e) {
      _logger.e('Error loading OAuth state', error: e);
      return null;
    }
  }

  @override
  Future<void> clearOAuthState(String state) async {
    if (!kIsWeb) return;

    try {
      web.window.sessionStorage['oauth_state_$state'] = '';
    } on Exception catch (e) {
      _logger.e('Error clearing OAuth state', error: e);
    }
  }
}
