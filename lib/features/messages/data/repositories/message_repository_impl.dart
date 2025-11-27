import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/mappers/message_dto_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRepository)
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remoteDataSource, this._logger);

  final MessageRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: conversationId -> messages (ordered)
  final Map<String, List<Message>> _cachedMessages = {};

  // Track loaded ranges per conversation: conversationId -> Set<(start, stop)>
  final Map<String, Set<String>> _loadedRanges = {};

  @override
  Future<Result<List<Message>>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  }) async {
    try {
      final stop = start + count;
      final rangeKey = '$start-$stop';

      // Check if we already loaded this range
      if (_loadedRanges[conversationId]?.contains(rangeKey) ?? false) {
        final cached = _cachedMessages[conversationId] ?? [];
        return success(cached.where((m) {
          // Filter messages in the requested range
          // This is a simple filter; you may need sequence numbers from API
          return true; // For now, return all cached
        }).toList(),);
      }

      final messageDtos = await _remoteDataSource.getMessages(
        conversationId: conversationId,
        start: start,
        count: count,
      );

      final messages = messageDtos.map((dto) => dto.toDomain()).toList();

      // Merge with cache, removing duplicates
      final existingMessages = _cachedMessages[conversationId] ?? [];
      final allMessages = <Message>[...existingMessages];

      for (final message in messages) {
        if (!allMessages.any((m) => m.id == message.id)) {
          allMessages.add(message);
        }
      }

      // Sort by date (newest first)
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the result
      _cachedMessages[conversationId] = allMessages;
      _loadedRanges.putIfAbsent(conversationId, () => {}).add(rangeKey);

      return success(messages);
    } on ServerException catch (e) {
      _logger.e('Server error fetching messages', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching messages', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching messages', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Message>> getMessage(String messageId) async {
    try {
      // Check cache across all conversations
      for (final messages in _cachedMessages.values) {
        final cached = messages.where((m) => m.id == messageId).firstOrNull;
        if (cached != null) {
          return success(cached);
        }
      }

      final messageDto = await _remoteDataSource.getMessage(messageId);
      final message = messageDto.toDomain();

      // Add to cache for the conversation
      final existingMessages = _cachedMessages[message.conversationId] ?? [];
      if (!existingMessages.any((m) => m.id == message.id)) {
        existingMessages.add(message);
        existingMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cachedMessages[message.conversationId] = existingMessages;
      }

      return success(message);
    } on ServerException catch (e) {
      _logger.e('Server error fetching message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on FormatException catch (e) {
      _logger.w('Invalid message data from API: ${e.message}');
      final serverFailure = ServerFailure(statusCode: 422, details: 'Invalid message data received from server: ${e.message}');
      return failure<Message>(serverFailure);
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching message - Exception caught: ${e.runtimeType}: $e', stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<Message>>> getMessagesFromConversations({
    required Set<String> conversationIds,
    int count = 50,
  }) async {
    try {
      final allMessages = <Message>[];

      // Clear cache for conversations that are no longer selected
      // This ensures we don't show stale data when switching conversations
      final cachedConversationIds = _cachedMessages.keys.toSet();
      final removedConversations = cachedConversationIds.difference(conversationIds);
      for (final removedId in removedConversations) {
        _cachedMessages.remove(removedId);
        _loadedRanges.remove(removedId);
      }

      // Fetch messages from each conversation using sequential pagination
      for (final conversationId in conversationIds) {
        try {
          final messageDtos = await _remoteDataSource.getMessages(
            conversationId: conversationId,
            start: 0, // Start from the beginning (most recent)
            count: count,
          );

          final messages = messageDtos.map((dto) => dto.toDomain()).toList();
          allMessages.addAll(messages);
        } on Exception catch (e) {
          // Log warning but continue with other conversations
          _logger.e('Failed to fetch messages from $conversationId: $e');
        }
      }

      // Sort all messages by date (newest first)
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return success(allMessages);
    } on Exception catch (e, stack) {
      _logger.e('Error fetching messages from multiple conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears message cache for a specific conversation
  void clearCacheForConversation(String conversationId) {
    _cachedMessages.remove(conversationId);
    _loadedRanges.remove(conversationId);
  }

  /// Clears all message cache
  void clearCache() {
    _cachedMessages.clear();
    _loadedRanges.clear();
  }
}
