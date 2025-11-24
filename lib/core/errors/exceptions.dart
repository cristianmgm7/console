class ServerException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ServerException({
    required this.statusCode,
    required this.message,
    this.code,
  });
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}

class StorageException implements Exception {
  final String message;
  StorageException({required this.message});
}

class OAuthException implements Exception {
  final String message;
  final String? code;
  OAuthException({required this.message, this.code});
}
