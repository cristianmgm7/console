import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  const LoginRequested();
}

class OAuthCallbackReceived extends AuthEvent {
  final String code;
  final String state;

  const OAuthCallbackReceived({
    required this.code,
    required this.state,
  });

  @override
  List<Object?> get props => [code, state];
}

class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
