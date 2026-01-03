import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_actions.dart';
import 'package:equatable/equatable.dart';

sealed class McpAuthEvent extends Equatable {
  const McpAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening for authentication requests for a session
/// @deprecated Use AuthRequestDetected instead (avoids duplicate API calls)
@Deprecated('Use AuthRequestDetected instead')
class StartAuthListening extends McpAuthEvent {
  const StartAuthListening({
    required this.sessionId,
    required this.message,
    this.context,
  });

  final String sessionId;
  final String message;
  final Map<String, dynamic>? context;

  @override
  List<Object?> get props => [sessionId, message, context];
}

/// Authentication request detected (forwarded from ChatBloc)
class AuthRequestDetected extends McpAuthEvent {
  const AuthRequestDetected({
    required this.sessionId,
    required this.requests,
  });

  final String sessionId;
  final List<AuthenticationRequest> requests;

  @override
  List<Object?> get props => [sessionId, requests];
}

/// User provided authorization code from OAuth flow
class AuthCodeProvided extends McpAuthEvent {
  const AuthCodeProvided({
    required this.authorizationCode,
    required this.request,
    required this.sessionId,
  });

  final String authorizationCode;
  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [authorizationCode, request, sessionId];
}

/// User cancelled authentication
class AuthCancelled extends McpAuthEvent {
  const AuthCancelled({
    required this.request,
    required this.sessionId,
  });

  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [request, sessionId];
}

/// Event fired when an authorization code is provided via deep link callback.
///
/// This is different from AuthCodeProvided which is for manual code entry.
/// This event includes the state parameter for validation and needs to
/// match it with the pending auth request.
class AuthCodeProvidedFromDeepLink extends McpAuthEvent {
  const AuthCodeProvidedFromDeepLink({
    required this.authorizationCode,
    required this.state,
  });

  final String authorizationCode;
  final String state;

  @override
  List<Object?> get props => [authorizationCode, state];
}

/// Stop listening for authentication requests
class StopAuthListening extends McpAuthEvent {
  const StopAuthListening();
}
