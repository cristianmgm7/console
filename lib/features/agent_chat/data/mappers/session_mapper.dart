import 'package:carbon_voice_console/features/agent_chat/data/models/session_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

extension SessionDtoMapper on SessionDto {
  AgentChatSession toDomain() {
    final lastUpdateDateTime = DateTime.fromMillisecondsSinceEpoch(
      (lastUpdateTime * 1000).toInt(),
    );

    // Extract last message preview from events if available
    String? preview;
    if (events.isNotEmpty) {
      try {
        final lastEvent = events.last as Map<String, dynamic>;
        final content = lastEvent['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final firstPart = parts.first as Map<String, dynamic>;
          preview = firstPart['text'] as String?;
          if (preview != null && preview.length > 50) {
            preview = '${preview.substring(0, 50)}...';
          }
        }
      } catch (e) {
        // Ignore parsing errors for preview
      }
    }

    return AgentChatSession(
      id: id,
      userId: userId,
      appName: appName,
      createdAt: lastUpdateDateTime, // ADK doesn't provide createdAt, use lastUpdate
      lastUpdateTime: lastUpdateDateTime,
      state: state,
      lastMessagePreview: preview,
    );
  }
}
