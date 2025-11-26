import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: ConversationRepository)
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource, this._logger);

  final ConversationRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: workspaceId -> conversations
  final Map<String, List<Conversation>> _cachedConversations = {};

  @override
  Future<Result<List<Conversation>>> getConversations(String workspaceId) async {
    try {
      // Return cached conversations if available
      if (_cachedConversations.containsKey(workspaceId)) {
        _logger.d('Returning cached conversations for workspace: $workspaceId');
        return success(_cachedConversations[workspaceId]!);
      }

      final conversationModels = await _remoteDataSource.getConversations(workspaceId);

      // Assign color indices to conversations (0-9 for 10 distinct colors)
      final conversations = conversationModels
          .asMap()
          .entries
          .map((entry) => entry.value.toEntity(assignedColorIndex: entry.key % 10))
          .toList();

      // Cache the result
      _cachedConversations[workspaceId] = conversations;

      return success(conversations);
    } on ServerException catch (e) {
      _logger.e('Server error fetching conversations', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching conversations', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async {
    try {
      // Check cache across all workspaces
      for (final conversations in _cachedConversations.values) {
        final cached = conversations.where((c) => c.id == conversationId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached conversation: $conversationId');
          return success(cached);
        }
      }

      final conversationModel = await _remoteDataSource.getConversation(conversationId);
      return success(conversationModel.toEntity());
    } on ServerException catch (e) {
      _logger.e('Server error fetching conversation', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching conversation', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching conversation', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the conversation cache for a specific workspace
  void clearCacheForWorkspace(String workspaceId) {
    _cachedConversations.remove(workspaceId);
  }

  /// Clears all conversation cache
  void clearCache() {
    _cachedConversations.clear();
  }
}

