import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {

  AgentChatRepositoryImpl() {
    // Initialize with some mock data for Phase 3
    _initializeMockData();
  }
  final Map<String, List<AgentChatMessage>> _messages = {};
  final Uuid _uuid = const Uuid();

  void _initializeMockData() {
    // Messages for session_1
    _messages['session_1'] = [
      AgentChatMessage(
        id: 'msg_1_1',
        sessionId: 'session_1',
        role: MessageRole.user,
        content: 'Hello, can you help me analyze some data?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      AgentChatMessage(
        id: 'msg_1_2',
        sessionId: 'session_1',
        role: MessageRole.agent,
        content: "I'd be happy to help you analyze your data. What specific information are you looking for?",
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        subAgentName: 'Carbon Voice Agent',
      ),
    ];

    // Messages for session_2
    _messages['session_2'] = [
      AgentChatMessage(
        id: 'msg_2_1',
        sessionId: 'session_2',
        role: MessageRole.user,
        content: 'What are the latest market trends?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AgentChatMessage(
        id: 'msg_2_2',
        sessionId: 'session_2',
        role: MessageRole.agent,
        content: 'I can help you with market analysis. Let me check the latest trends for you.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        subAgentName: 'Market Analyzer',
      ),
    ];

    // Messages for session_3 - empty for now
    _messages['session_3'] = [];
  }

  @override
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return success(_messages[sessionId]?.toList() ?? []);
  }

  @override
  Future<Result<List<AgentChatMessage>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create agent response based on content
    final agentResponse = _generateAgentResponse(content);

    final agentMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.agent,
      content: agentResponse['content'] as String,
      timestamp: DateTime.now(),
      subAgentName: agentResponse['subAgentName'] as String?,
    );

    // Add to messages
    _messages[sessionId] ??= [];
    _messages[sessionId]!.add(agentMessage);

    return success([agentMessage]);
  }

  Map<String, dynamic> _generateAgentResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('github') || lowerMessage.contains('repo')) {
      return {
        'content': 'I can help you analyze your GitHub repositories. Let me check what repositories you have and provide some insights.',
        'subAgentName': 'GitHub Agent',
      };
    } else if (lowerMessage.contains('market') || lowerMessage.contains('trend')) {
      return {
        'content': 'I\'ll analyze the current market trends for you. Based on recent data, there are some interesting patterns emerging.',
        'subAgentName': 'Market Analyzer',
      };
    } else if (lowerMessage.contains('data') || lowerMessage.contains('analyze')) {
      return {
        'content': 'I can help you analyze your data. What type of data are you working with and what insights are you looking for?',
        'subAgentName': 'Carbon Voice Agent',
      };
    } else {
      return {
        'content': 'I understand you\'re asking about: "$userMessage". How can I help you with this?',
        'subAgentName': 'Carbon Voice Agent',
      };
    }
  }

  @override
  Future<Result<void>> saveMessagesLocally(String sessionId, List<AgentChatMessage> messages) async {
    // For Phase 3, just store in memory
    _messages[sessionId] = messages;
    return success(null);
  }
}
