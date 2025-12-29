import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

sealed class McpAuthState extends Equatable {
  const McpAuthState();

  @override
  List<Object?> get props => [];
}

class McpAuthInitial extends McpAuthState {
  const McpAuthInitial();
}

class McpAuthListening extends McpAuthState {
  const McpAuthListening({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Authentication is required - show dialog
class McpAuthRequired extends McpAuthState {
  const McpAuthRequired({
    required this.request,
    required this.sessionId,
  });

  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [request, sessionId];
}

/// Processing authentication (exchanging code for token)
class McpAuthProcessing extends McpAuthState {
  const McpAuthProcessing({
    required this.provider,
    required this.sessionId,
  });

  final String provider;
  final String sessionId;

  @override
  List<Object?> get props => [provider, sessionId];
}

/// Authentication completed successfully
class McpAuthSuccess extends McpAuthState {
  const McpAuthSuccess({
    required this.provider,
    required this.sessionId,
  });

  final String provider;
  final String sessionId;

  @override
  List<Object?> get props => [provider, sessionId];
}

/// Authentication failed
class McpAuthError extends McpAuthState {
  const McpAuthError({
    required this.message,
    required this.sessionId,
  });

  final String message;
  final String sessionId;

  @override
  List<Object?> get props => [message, sessionId];
}
