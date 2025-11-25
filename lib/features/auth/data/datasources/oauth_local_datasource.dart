import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'dart:convert';
import 'dart:html' as html; 

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
  static const _credentialsKey = 'oauth_credentials';
  final FlutterSecureStorage _storage;

  OAuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveCredentials(oauth2.Credentials credentials) async {
    final json = credentials.toJson();
    await _storage.write(key: _credentialsKey, value: jsonEncode(json));
  }

  @override
  Future<oauth2.Credentials?> loadCredentials() async {
    final jsonString = await _storage.read(key: _credentialsKey);
    if (jsonString == null) return null;

    try {
      // oauth2.Credentials.fromJson expects a JSON string, not a Map
      return oauth2.Credentials.fromJson(jsonString);
    } catch (e) {
      // Credentials corruptas o formato antiguo
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
      html.window.sessionStorage['oauth_state_$state'] = jsonEncode(data);

    } catch (e) {

    }
  }

  @override
  Future<Map<String, String>?> loadOAuthState(String state) async {
    if (!kIsWeb) return null;
    
    try {
      final dataStr = html.window.sessionStorage['oauth_state_$state'];
      if (dataStr == null) {

        return null;
      }
      
      final data = jsonDecode(dataStr) as Map<String, dynamic>;

      return {
        'state': data['state'] as String,
        'codeVerifier': data['codeVerifier'] as String,
      };
    } catch (e) {

      return null;
    }
  }

  @override
  Future<void> clearOAuthState(String state) async {
    if (!kIsWeb) return;
    
    try {
      html.window.sessionStorage.remove('oauth_state_$state');

    } catch (e) {

    }
  }
}
