import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_actions.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_auth.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_content.dart';
import 'package:equatable/equatable.dart';

/// Represents a complete ADK event from the agent execution stream.
///
/// This entity preserves all information from the ADK backend, including:
/// - Text content and function calls/responses
/// - Authentication requests
/// - Status updates and control signals
/// - Multi-part content with text, images, and structured data
///
/// Unlike the old architecture, this entity is NOT filtered - all events
/// are preserved and categorized by use cases at the application layer.
class AdkEvent extends Equatable {
  const AdkEvent({
    required this.id,
    required this.invocationId,
    required this.author,
    required this.timestamp,
    required this.content,
    this.actions,
    this.partial = false,
    this.branch,
    this.longRunningToolIds,
  });

  final String id;
  final String invocationId;
  final String author;
  final DateTime timestamp;
  final AdkContent content;
  final AdkActions? actions;
  final bool partial;
  final String? branch;
  final List<String>? longRunningToolIds;

  @override
  List<Object?> get props => [
        id,
        invocationId,
        author,
        timestamp,
        content,
        actions,
        partial,
        branch,
        longRunningToolIds,
      ];


  /// Check if this is a final user-facing response (text message).
  ///
  /// Returns true if this event contains text content that should be displayed
  /// to the user, and has completed processing (not partial) with no outstanding
  /// function calls.
  bool get isFinalResponse {
    if (partial) return false;
    if (content.parts.isEmpty) return false;

    // Has text and no function calls
    final hasText = content.parts.any((p) => p is AdkTextPart);
    final hasFunctionCalls = content.parts.any((p) => p is AdkFunctionCallPart);

    return hasText && !hasFunctionCalls;
  }

  /// Check if this event contains an authentication request.
  ///
  /// Returns true if this event contains requested auth configs in the actions,
  /// which requires the user to authenticate with an external service (GitHub, etc.)
  /// to enable MCP tools.
  bool get isAuthenticationRequest {
    return actions?.requestedAuthConfigs != null &&
        actions!.requestedAuthConfigs!.isNotEmpty;
  }
  bool get isToolConfirmationRequest {
    return actions?.requestedToolConfirmations != null &&
        actions!.requestedToolConfirmations!.isNotEmpty;
  }

  /// Extract authentication request details if present.
  ///
  /// Returns an [AuthenticationRequest] object containing the OAuth2 parameters
  /// needed to authenticate with the requested provider. Returns null if this
  /// event does not contain an authentication request.
  ///
  /// Use this in conjunction with isAuthenticationRequest to handle auth flows.
  AuthenticationRequest? get authenticationRequest {
    if (actions?.requestedAuthConfigs == null ||
        actions!.requestedAuthConfigs!.isEmpty) {
      return null;
    }

    // Get the first auth config from the map
    final authConfig = actions!.requestedAuthConfigs!.values.first;
    return AuthenticationRequest.fromAuthConfig(authConfig);
  }

  /// Get all function calls in this event
  List<AdkFunctionCallPart> get functionCalls {
    final calls = <AdkFunctionCallPart>[];

    // From parts
    for (final part in content.parts) {
      if (part is AdkFunctionCallPart) {
        calls.add(part);
      }
    }

    return calls;
  }

  /// Get text content from this event
  String? get textContent {
    final textParts = content.parts
        .whereType<AdkTextPart>()
        .map((p) => p.text)
        .toList();

    if (textParts.isEmpty) return null;
    return textParts.join('\n');
  }
}
