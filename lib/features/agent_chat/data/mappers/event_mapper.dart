import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

extension EventDtoMapper on EventDto {
  AgentChatMessage? toDomain(String sessionId) {
    // Only convert events with text content from agent responses
    if (content.role != 'model') return null;

    final textParts = content.parts.where((p) => p.text != null).toList();
    if (textParts.isEmpty) return null;

    final combinedText = textParts.map((p) => p.text!).join('\n');

    // Determine sub-agent from author field
    String? subAgentName;
    String? subAgentIcon;

    if (author.contains('github')) {
      subAgentName = 'GitHub Agent';
      subAgentIcon = 'github';
    } else if (author.contains('carbon')) {
      subAgentName = 'Carbon Voice Agent';
      subAgentIcon = 'chat';
    } else if (author.contains('market') || author.contains('analyzer')) {
      subAgentName = 'Market Analyzer';
      subAgentIcon = 'chart_line';
    }

    return AgentChatMessage(
      id: id ?? '',
      sessionId: sessionId,
      role: MessageRole.agent,
      content: combinedText,
      timestamp: timestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
          : DateTime.now(),
      subAgentName: subAgentName,
      subAgentIcon: subAgentIcon,
      metadata: {
        'invocationId': invocationId ?? '',
        'author': author,
      },
    );
  }

  /// Extract status message for function calls
  String? getStatusMessage() {
    // Check actions first (OpenAPI spec)
    final actionsCalls = actions?.functionCalls ?? [];
    if (actionsCalls.isNotEmpty) {
      final call = actionsCalls.first;
      return 'Calling ${call.name}...';
    }

    // Check parts for interleaved calls (ADK/Gemini style)
    for (final part in content.parts) {
      if (part.functionCall != null) {
        return 'Calling ${part.functionCall!.name}...';
      }
    }

    return null;
  }
}
