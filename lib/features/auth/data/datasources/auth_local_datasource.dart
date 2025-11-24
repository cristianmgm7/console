import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../infrastructure/services/secure_storage_service.dart';
import '../models/token_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(TokenModel token);
  Future<TokenModel?> loadToken();
  Future<void> deleteToken();
  Future<void> clearAllData();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storage;
  static const String _tokenKey = 'auth_token';

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveToken(TokenModel token) async {
    try {
      final jsonString = jsonEncode(token.toJson());
      await _storage.write(key: _tokenKey, value: jsonString);
    } catch (e) {
      throw StorageException(message: e.toString());
    }
  }

  @override
  Future<TokenModel?> loadToken() async {
    try {
      final jsonString = await _storage.read(key: _tokenKey);
      if (jsonString == null) return null;

      return TokenModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      throw StorageException(message: e.toString());
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      throw StorageException(message: e.toString());
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(message: e.toString());
    }
  }
}
