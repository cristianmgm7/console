import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_auth.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all chat items that can appear in the chat UI.
///
/// This polymorphic approach allows the UI to handle different types of
/// chat items (messages, auth requests, status indicators) using pattern
/// matching (switch expressions) for type-safe rendering.
sealed class ChatItem extends Equatable {
  const ChatItem({
    required this.id,
    required this.timestamp,
    this.subAgentName,
    this.subAgentIcon,
  });

  final String id;
  final DateTime timestamp;
  final String? subAgentName;
  final String? subAgentIcon;

  @override
  List<Object?> get props => [id, timestamp, subAgentName, subAgentIcon];
}

/// Message role for text messages
enum MessageRole {
  user,
  agent,
  system,
}

/// Status type for system status items
enum StatusType {
  thinking,
  handoff,
  error,
  complete,
  toolCall,
}

/// 1. Standard Text Message
///
/// Represents a text message from the user, agent, or system.
/// Used for displaying chat bubbles in the conversation.
class TextMessageItem extends ChatItem {
  const TextMessageItem({
    required super.id,
    required super.timestamp,
    required this.text,
    required this.role,
    super.subAgentName,
    super.subAgentIcon,
    this.isPartial = false,
    this.hasA2Ui = false,
  });

  final String text;
  final MessageRole role;
  final bool isPartial;
  final bool hasA2Ui;

  @override
  List<Object?> get props => [...super.props, text, role, isPartial, hasA2Ui];

  TextMessageItem copyWith({
    String? id,
    DateTime? timestamp,
    String? text,
    MessageRole? role,
    String? subAgentName,
    String? subAgentIcon,
    bool? isPartial,
    bool? hasA2Ui,
  }) {
    return TextMessageItem(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      role: role ?? this.role,
      subAgentName: subAgentName ?? this.subAgentName,
      subAgentIcon: subAgentIcon ?? this.subAgentIcon,
      isPartial: isPartial ?? this.isPartial,
      hasA2Ui: hasA2Ui ?? this.hasA2Ui,
    );
  }
}

/// 2. Interactive Auth Request
///
/// Represents an authentication request from the agent that requires
/// user interaction. Displays as an actionable card in the chat.
class AuthRequestItem extends ChatItem {
  const AuthRequestItem({
    required super.id,
    required super.timestamp,
    required this.request,
    super.subAgentName,
    super.subAgentIcon,
  });

  final AuthenticationRequest request;

  @override
  List<Object?> get props => [...super.props, request];
}

/// 3. System Status (Thinking, Handoffs, Tool Calls, Errors)
///
/// Represents a system status indicator in the chat.
/// Used for showing "thinking...", "Calling function X...", handoffs, etc.
class SystemStatusItem extends ChatItem {
  const SystemStatusItem({
    required super.id,
    required super.timestamp,
    required this.status,
    required this.type,
    super.subAgentName,
    super.subAgentIcon,
    this.metadata,
  });

  final String status;
  final StatusType type;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [...super.props, status, type, metadata];

  SystemStatusItem copyWith({
    String? id,
    DateTime? timestamp,
    String? status,
    StatusType? type,
    String? subAgentName,
    String? subAgentIcon,
    Map<String, dynamic>? metadata,
  }) {
    return SystemStatusItem(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      subAgentName: subAgentName ?? this.subAgentName,
      subAgentIcon: subAgentIcon ?? this.subAgentIcon,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 4. Tool Confirmation Request
///
/// Represents a request for user confirmation before executing a sensitive tool.
class ToolConfirmationItem extends ChatItem {
  const ToolConfirmationItem({
    required super.id,
    required super.timestamp,
    required this.toolCallId,
    required this.functionName,
    required this.args,
    super.subAgentName,
    super.subAgentIcon,
  });

  final String toolCallId;
  final String functionName;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [
        ...super.props,
        toolCallId,
        functionName,
        args,
      ];
}
