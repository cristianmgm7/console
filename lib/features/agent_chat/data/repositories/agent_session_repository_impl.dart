import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_session_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: AgentSessionRepository)
class AgentSessionRepositoryImpl implements AgentSessionRepository {
  final List<AgentChatSession> _sessions = [];
  final Uuid _uuid = const Uuid();

  AgentSessionRepositoryImpl() {
    // Initialize with some mock data for Phase 3
    _initializeMockData();
  }

  void _initializeMockData() {
    _sessions.addAll([
      AgentChatSession(
        id: 'session_1',
        userId: 'user_123',
        appName: 'root_agent',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastUpdateTime: DateTime.now().subtract(const Duration(hours: 2)),
        lastMessagePreview: 'Hello, can you help me analyze some data?',
      ),
      AgentChatSession(
        id: 'session_2',
        userId: 'user_123',
        appName: 'root_agent',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastUpdateTime: DateTime.now().subtract(const Duration(hours: 1)),
        lastMessagePreview: 'What are the latest market trends?',
      ),
      AgentChatSession(
        id: 'session_3',
        userId: 'user_123',
        appName: 'root_agent',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lastUpdateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        lastMessagePreview: 'Please review my GitHub repositories',
      ),
    ]);
  }

  @override
  Future<Result<List<AgentChatSession>>> loadSessions() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return success(_sessions.toList());
  }

  @override
  Future<Result<AgentChatSession>> createSession(String sessionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final newSession = AgentChatSession(
      id: sessionId,
      userId: 'user_123',
      appName: 'root_agent',
      createdAt: DateTime.now(),
      lastUpdateTime: DateTime.now(),
    );

    _sessions.insert(0, newSession); // Add to beginning
    return success(newSession);
  }

  @override
  Future<Result<AgentChatSession>> getSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    return success(session);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _sessions.removeWhere((s) => s.id == sessionId);
    return success(null);
  }

  @override
  Future<Result<void>> saveSessionLocally(AgentChatSession session) async {
    // For Phase 3, just store in memory
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
    } else {
      _sessions.add(session);
    }
    return success(null);
  }
}
