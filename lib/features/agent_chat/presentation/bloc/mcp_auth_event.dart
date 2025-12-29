import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

sealed class McpAuthEvent extends Equatable {
  const McpAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening for authentication requests for a session
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

/// Stop listening for authentication requests
class StopAuthListening extends McpAuthEvent {
  const StopAuthListening();
}
