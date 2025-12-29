import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

abstract class AgentChatRepository {
  /// Send a message and receive a stream of ADK events
  ///
  /// This stream includes all events from the agent: text responses,
  /// function calls, authentication requests, status updates, etc.
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  });

  /// Send authentication credentials back to the ADK agent
  ///
  /// This is called after the user completes OAuth flow for MCP tools
  Future<void> sendAuthenticationCredentials({
    required String sessionId,
    required String provider,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  });
}
