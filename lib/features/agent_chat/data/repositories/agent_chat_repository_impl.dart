import 'dart:convert';

import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {

  AgentChatRepositoryImpl(
    this._apiService,
    this._storage,
    this._logger,
  );
  final AdkApiService _apiService;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'test_user'; // Placeholder - matches ADK test user
  }

  String _getMessagesKey(String sessionId) => 'agent_chat_messages_$sessionId';

  @override
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId) async {
    try {
      final messagesJson = await _storage.read(key: _getMessagesKey(sessionId));

      if (messagesJson == null) {
        return success([]);
      }

      final messagesList = jsonDecode(messagesJson) as List;
      final messages = messagesList
          .map((json) => _messageFromJson(json as Map<String, dynamic>))
          .toList();

      return success(messages);
    } on StorageException catch (e) {
      _logger.e('Error loading messages', error: e);
      return failure(const StorageFailure(details: 'Failed to load messages'));
    }
  }

  @override
  Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
    required String sessionId,
    required String content,
    required void Function(String status, String? subAgent) onStatus, Map<String, dynamic>? context,
    void Function(String chunk)? onMessageChunk,
  }) async {
    try {
      final agentMessages = <AgentChatMessage>[];

      await for (final eventJson in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      )) {
        final eventDto = EventDto.fromJson(eventJson);

        // Check for status updates (function calls)
        final statusMsg = eventDto.getStatusMessage();
        if (statusMsg != null) {
          String? subAgent;
          if (eventDto.author.contains('github')) {
            subAgent = 'GitHub Agent';
          } else if (eventDto.author.contains('carbon')) {
            subAgent = 'Carbon Voice Agent';
          } else if (eventDto.author.contains('market') || eventDto.author.contains('analyzer')) {
            subAgent = 'Market Analyzer';
          }

          onStatus(statusMsg, subAgent);
        }

        // Convert to message
        final message = eventDto.toDomain(sessionId);
        if (message != null) {
          agentMessages.add(message);
        }
      }

      // Save messages locally
      if (agentMessages.isNotEmpty) {
        final existingMessages = await loadMessages(sessionId);
        final allMessages = [
          ...existingMessages.fold(onSuccess: (m) => m, onFailure: (_) => <AgentChatMessage>[]),
          ...agentMessages,
        ];
        await saveMessagesLocally(sessionId, allMessages);
      }

      return success(agentMessages);
    } on ServerException catch (e) {
      _logger.e('Server error streaming message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error streaming message', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error streaming message', error: e);
      return failure(const UnknownFailure(details: 'Failed to stream message'));
    }
  }

  @override
  Future<Result<void>> saveMessagesLocally(
    String sessionId,
    List<AgentChatMessage> messages,
  ) async {
    try {
      final messagesJson = jsonEncode(
        messages.map((m) => _messageToJson(m)).toList(),
      );

      await _storage.write(key: _getMessagesKey(sessionId), value: messagesJson);

      return success(null);
    } catch (e) {
      _logger.e('Error saving messages locally', error: e);
      return failure(const StorageFailure(details: 'Failed to save messages'));
    }
  }

  Map<String, dynamic> _messageToJson(AgentChatMessage message) {
    return {
      'id': message.id,
      'sessionId': message.sessionId,
      'role': message.role.name,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'status': message.status.name,
      'subAgentName': message.subAgentName,
      'subAgentIcon': message.subAgentIcon,
      'metadata': message.metadata,
    };
  }

  AgentChatMessage _messageFromJson(Map<String, dynamic> json) {
    return AgentChatMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: MessageRole.values.firstWhere((r) => r.name == json['role']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere((s) => s.name == json['status']),
      subAgentName: json['subAgentName'] as String?,
      subAgentIcon: json['subAgentIcon'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
