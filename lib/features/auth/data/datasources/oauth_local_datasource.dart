import 'dart:convert';

import 'package:carbon_voice_console/core/web/web_stub.dart'
    if (dart.library.html) 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

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
    final encoded = jsonEncode(json);
    await _storage.write(key: _credentialsKey, value: encoded);
  }

  @override
  Future<oauth2.Credentials?> loadCredentials() async {
    final jsonString = await _storage.read(key: _credentialsKey);
    if (jsonString == null) return null;
    try {
      // oauth2.Credentials.fromJson expects a JSON string representing the credentials
      return oauth2.Credentials.fromJson(jsonString);
    } on Exception catch (e) {
      _logger.e('Error loading credentials', error: e);
      // Credentials corrupted or old format
      return null;
    }
  }

  @override
  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
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
