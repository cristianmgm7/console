import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PKCEGenerator {
  /// Generate cryptographically secure random code_verifier
  /// Length between 43-128 characters (RFC 7636)
  static String generateCodeVerifier() {
    const length = 128;
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generate code_challenge from code_verifier using S256 method
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);

    // Base64 URL encode without padding
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generate state parameter for CSRF protection
  static String generateState() {
    const length = 32;
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }
}

