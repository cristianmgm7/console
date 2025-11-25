import '../errors/failures.dart';

/// Maps domain failures to user-friendly messages
/// Keeps domain layer pure and enables i18n
class FailureMapper {
  FailureMapper._();

  static String mapToMessage(AppFailure failure) {
    return switch (failure) {
      TokenExpiredFailure() => 'Your session has expired. Please login again.',
      InvalidCredentialsFailure() => 'Invalid credentials. Please try again.',
      InvalidStateFailure() => 'Security validation failed. Please try again.',
      UserCancelledFailure() => 'Login was cancelled.',
      NetworkFailure(details: final d) => 'Network error. ${d ?? "Please check your connection."}',
      ServerFailure(statusCode: final code, details: final d) =>
        'Server error ($code). ${d ?? "Please try again later."}',
      StorageFailure(details: final d) => 'Storage error. ${d ?? "Please try again."}',
      ConfigurationFailure(details: final d) => 'Configuration error: ${d ?? "Contact support."}',
      AuthFailure(code: final c, details: final d) => 'Authentication failed: ${d ?? c}',
      UnknownFailure(details: final d) => 'An unexpected error occurred. ${d ?? ""}',
    };
  }

  /// For i18n, return translation key instead
  static String mapToI18nKey(AppFailure failure) {
    return switch (failure) {
      TokenExpiredFailure() => 'error.token_expired',
      InvalidCredentialsFailure() => 'error.invalid_credentials',
      InvalidStateFailure() => 'error.invalid_state',
      UserCancelledFailure() => 'error.user_cancelled',
      NetworkFailure() => 'error.network',
      ServerFailure() => 'error.server',
      StorageFailure() => 'error.storage',
      ConfigurationFailure() => 'error.configuration',
      AuthFailure() => 'error.auth',
      UnknownFailure() => 'error.unknown',
    };
  }
}
