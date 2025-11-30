import 'dart:convert';

import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

/// Service para realizar llamadas HTTP autenticadas usando oauth2.Client
@LazySingleton()
class AuthenticatedHttpService {
  AuthenticatedHttpService(this._oauthRepository);

  final OAuthRepository _oauthRepository;

  /// Obtiene el cliente oauth2 (con refresh automático)
  Future<oauth2.Client?> _getClient() async {
    final result = await _oauthRepository.getClient();
    return result.fold(
      onSuccess: (client) => client,
      onFailure: (_) => null,
    );
  }

  /// GET request autenticado
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    // oauth2.Client automáticamente agrega Authorization header
    // y refresca el token si es necesario
    return client.get(
      Uri.parse(path),
      headers: headers,
    );
  }

  /// POST request autenticado
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.post(
      Uri.parse(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PUT request autenticado
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.put(
      Uri.parse(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// DELETE request autenticado
  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.delete(
      Uri.parse(path),
      headers: headers,
    );
  }

  /// Get current authentication headers for external use
  Future<Map<String, String>> getAuthHeaders() async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('No valid access token available');
    }

    return {
      'Authorization': client.credentials.accessToken,
    };
  }
}
