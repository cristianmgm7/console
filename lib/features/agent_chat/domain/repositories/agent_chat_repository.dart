import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

/// Repository interface for ADK agent chat functionality.
///
/// This repository provides access to ADK (Agent Development Kit) backend
/// communication. Unlike the old implementation that filtered and accumulated
/// events, this repository preserves the full event stream for processing
/// by domain use cases at the application layer.
abstract class AgentChatRepository {
  /// Send a message and receive a stream of ADK events.
  ///
  /// This method returns a Result containing a stream of ALL events from the agent execution:
  /// - Text responses (complete and partial)
  /// - Function calls and responses
  /// - Authentication requests for MCP tools
  /// - Status updates and control signals
  /// - Errors and state changes
  ///
  /// The stream preserves event ordering and timing, enabling real-time
  /// UI updates and proper handling of streaming responses.
  ///
  /// Use cases filter this stream for specific event types they handle.
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  });

  /// Send authentication credentials back to the ADK agent.
  ///
  /// This method is called after the user completes OAuth2 authentication
  /// for MCP (Model Context Protocol) tools. The credentials are sent back
  /// to the agent as a function response, enabling the agent to use authenticated
  /// APIs (GitHub, etc.) on behalf of the user.
  ///
  /// The agent acknowledges receipt and can then proceed with tool usage.
  Future<Result<void>> sendAuthenticationCredentials({
    required String sessionId,
    required String provider,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  });
}
