import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

abstract class AgentChatRepository {
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId);
  Future<Result<List<AgentChatMessage>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  });
  Future<Result<void>> saveMessagesLocally(String sessionId, List<AgentChatMessage> messages);
}
