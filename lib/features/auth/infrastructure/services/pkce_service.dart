import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class PKCEService {
  static const _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  String generateCodeVerifier() {
    final random = Random.secure();
    return List.generate(
      128,
      (i) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String generateState() {
    final random = Random.secure();
    return List.generate(
      32,
      (i) => _charset[random.nextInt(_charset.length)],
    ).join();
  }
}
