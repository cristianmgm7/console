import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'dart:convert';

abstract class OAuthLocalDataSource {
  Future<void> saveCredentials(oauth2.Credentials credentials);
  Future<oauth2.Credentials?> loadCredentials();
  Future<void> deleteCredentials();
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
}
