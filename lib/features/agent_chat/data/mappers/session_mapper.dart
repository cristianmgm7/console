import 'package:carbon_voice_console/core/api/generated/lib/api.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/adk_event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

extension SessionMapper on Session {
  AgentChatSession toDomain() {
    final lastUpdateDateTime = lastUpdateTime != null
        ? DateTime.fromMillisecondsSinceEpoch((lastUpdateTime! * 1000).toInt())
        : DateTime.now();

    // Extract last message preview from events if available
    String? preview;
    if (events.isNotEmpty) {
      try {
        final lastEvent = events.last;
        final adkEvent = lastEvent.toAdkEvent();
        final textContent = adkEvent.textContent;
        if (textContent != null && textContent.isNotEmpty) {
          preview = textContent.length > 50
              ? '${textContent.substring(0, 50)}...'
              : textContent;
        }
      } on Exception {
        // Ignore parsing errors for preview
      }
    }

    return AgentChatSession(
      id: id,
      userId: userId,
      appName: appName,
      createdAt: lastUpdateDateTime, // ADK doesn't provide createdAt, use lastUpdate
      lastUpdateTime: lastUpdateDateTime,
      state: state.cast<String, dynamic>(),
      lastMessagePreview: preview,
    );
  }
}
