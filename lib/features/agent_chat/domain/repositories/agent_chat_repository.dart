import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

/// Repository interface for ADK agent chat functionality.
///
/// This repository provides access to ADK (Agent Development Kit) backend
/// communication. Returns all events from the agent execution as a list
/// for simpler processing and debugging.
abstract class AgentChatRepository {
  /// Send a message and receive all ADK events at once.
  ///
  /// This method returns a Result containing ALL events from the agent execution:
  /// - Text responses (complete)
  /// - Function calls and responses
  /// - Authentication requests for MCP tools
  /// - Status updates and control signals
  /// - Errors and state changes
  ///
  /// Events are returned in order after the agent completes processing.
  /// Use cases filter this list for specific event types they handle.
  Future<Result<List<AdkEvent>>> sendMessage({
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
