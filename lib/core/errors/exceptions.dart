class ServerException implements Exception {

  ServerException({
    required this.statusCode,
    required this.message,
    this.code,
  });
  final int statusCode;
  final String message;
  final String? code;
}

class NetworkException implements Exception {
  NetworkException({required this.message});
  final String message;
}

class StorageException implements Exception {
  StorageException({required this.message});
  final String message;
}

class OAuthException implements Exception {
  OAuthException({required this.message, this.code});
  final String message;
  final String? code;
}
