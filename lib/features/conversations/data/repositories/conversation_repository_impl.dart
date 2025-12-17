import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/data/mappers/conversation_dto_mapper.dart';
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

  // Recent conversations cache (not workspace-specific) - used only for paging.
  final List<Conversation> _recentConversationsCache = [];

  @override
  Future<Result<List<Conversation>>> getConversations(String workspaceId) async {
    try {
      // Return cached conversations if available
      if (_cachedConversations.containsKey(workspaceId)) {
        _logger.d('Returning cached conversations for workspace: $workspaceId');
        return success(_cachedConversations[workspaceId]!);
      }

      final conversationDtos = await _remoteDataSource.getConversations(workspaceId);

      // Convert DTOs to domain entities
      final conversations = conversationDtos.map((dto) => dto.toDomain()).toList();

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
  Future<Result<List<Conversation>>> getRecentConversations({
    required String workspaceId,
    required int limit,
    String? beforeDate,
  }) async {
    try {
      // For the first page, use "now" to fetch the most recent channels.
      final dateToUse = beforeDate ?? DateTime.now().toIso8601String();

      final conversationDtos = await _remoteDataSource.getRecentChannels(
        limit: limit,
        direction: 'older',
        date: dateToUse,
        includeDeleted: false,
      );

      final conversations = conversationDtos.map((dto) => dto.toDomain()).toList();

      // Maintain a simple cache for potential future use/debugging.
      if (beforeDate == null) {
        _recentConversationsCache
          ..clear()
          ..addAll(conversations);
      } else {
        _recentConversationsCache.addAll(conversations);
      }

      // Filter by workspace on client-side
      final filtered = conversations.where((c) => c.workspaceGuid == workspaceId).toList();
      return success(filtered);
    } on ServerException catch (e) {
      _logger.e('Server error fetching recent conversations', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching recent conversations', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching recent conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async {
    try {
      // // Check cache across all workspaces
      // for (final conversations in _cachedConversations.values) {
      //   final cached = conversations.where((c) => c.channelGuid == conversationId).firstOrNull;
      //   if (cached != null) {
      //     _logger.d('Returning cached conversation: $conversationId');
      //     return success(cached);
      //   }
      // }

      final conversationDto = await _remoteDataSource.getConversation(conversationId);
      final conversation = conversationDto.toDomain();
      return success(conversation);
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

  /// Clears the recent conversations cache
  void clearRecentConversationsCache() {
    _recentConversationsCache.clear();
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
