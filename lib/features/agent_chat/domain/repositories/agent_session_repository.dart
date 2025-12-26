import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

abstract class AgentSessionRepository {
  Future<Result<List<AgentChatSession>>> loadSessions();
  Future<Result<AgentChatSession>> createSession(String sessionId);
  Future<Result<AgentChatSession>> getSession(String sessionId);
  Future<Result<void>> deleteSession(String sessionId);
  Future<Result<void>> saveSessionLocally(AgentChatSession session);
}
