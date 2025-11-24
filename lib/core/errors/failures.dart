import 'package:equatable/equatable.dart';

/// Base class for all domain failures
sealed class AppFailure extends Equatable {
  final String code;
  final String? details;

  const AppFailure({required this.code, this.details});

  @override
  List<Object?> get props => [code, details];
}

/// Authentication-specific failures
final class AuthFailure extends AppFailure {
  const AuthFailure({required super.code, super.details});
}

final class TokenExpiredFailure extends AppFailure {
  const TokenExpiredFailure()
      : super(code: 'TOKEN_EXPIRED');
}

final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure()
      : super(code: 'INVALID_CREDENTIALS');
}

final class InvalidStateFailure extends AppFailure {
  const InvalidStateFailure()
      : super(code: 'INVALID_STATE');
}

final class UserCancelledFailure extends AppFailure {
  const UserCancelledFailure()
      : super(code: 'USER_CANCELLED');
}

/// Network failures
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.details})
      : super(code: 'NETWORK_ERROR');
}

final class ServerFailure extends AppFailure {
  final int statusCode;

  const ServerFailure({
    required this.statusCode,
    super.details,
  }) : super(code: 'SERVER_ERROR');

  @override
  List<Object?> get props => [code, details, statusCode];
}

/// Storage failures
final class StorageFailure extends AppFailure {
  const StorageFailure({super.details})
      : super(code: 'STORAGE_ERROR');
}

/// Configuration failures
final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({super.details})
      : super(code: 'CONFIGURATION_ERROR');
}

/// Unknown failures
final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.details})
      : super(code: 'UNKNOWN_ERROR');
}
