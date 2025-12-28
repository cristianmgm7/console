import 'package:equatable/equatable.dart';

enum MessageRole { user, agent }

enum MessageStatus { sending, sent, error }

class AgentChatMessage extends Equatable {

  const AgentChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.subAgentName,
    this.subAgentIcon,
    this.metadata,
  });
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? subAgentName;
  final String? subAgentIcon;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        sessionId,
        role,
        content,
        timestamp,
        status,
        subAgentName,
        subAgentIcon,
        metadata,
      ];

  AgentChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? subAgentName,
    String? subAgentIcon,
    Map<String, dynamic>? metadata,
  }) {
    return AgentChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      subAgentName: subAgentName ?? this.subAgentName,
      subAgentIcon: subAgentIcon ?? this.subAgentIcon,
      metadata: metadata ?? this.metadata,
    );
  }
}
