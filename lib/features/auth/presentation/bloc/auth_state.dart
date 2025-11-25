import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({this.message});
  
  final String? message;

  @override
  List<Object?> get props => [message];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class RedirectToOAuth extends AuthState {
  const RedirectToOAuth(this.url);
  
  final String url;

  @override
  List<Object?> get props => [url];
}

class ProcessingCallback extends AuthState {
  const ProcessingCallback();
}

class LoggedOut extends AuthState {
  const LoggedOut();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
