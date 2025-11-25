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

// NEW: Maneja la URL de callback completa
class AuthorizationResponseReceived extends AuthEvent {

  const AuthorizationResponseReceived(this.responseUrl);
  final String responseUrl;

  @override
  List<Object?> get props => [responseUrl];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
