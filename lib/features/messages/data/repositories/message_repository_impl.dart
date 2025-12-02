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

  @override
  Future<Result<List<Message>>> getRecentMessages({
    required String conversationId,
    int count = 50,
    DateTime? beforeTimestamp,
  }) async {
    try {
      // If no timestamp provided, use current time as starting point
      final effectiveTimestamp = beforeTimestamp ?? DateTime.now();
      final beforeTimestampStr = effectiveTimestamp.toIso8601String();

      final messageDtos = await _remoteDataSource.getRecentMessages(
        conversationId: conversationId,
        count: count,
        beforeTimestamp: beforeTimestampStr,
      );

      final messages = messageDtos.map((dto) => dto.toDomain()).toList();

      // Ensure messages are sorted by date (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Merge with cache
      final existingMessages = _cachedMessages[conversationId] ?? [];
      final allMessages = <Message>[...existingMessages];

      for (final message in messages) {
        if (!allMessages.any((m) => m.id == message.id)) {
          allMessages.add(message);
        }
      }

      // Update cache
      _cachedMessages[conversationId] = allMessages;

      return success(messages);
    } on ServerException catch (e) {
      _logger.e('Server error fetching recent messages', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching recent messages', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching recent messages', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Message>> getMessage(String messageId, {bool includePreSignedUrls = false}) async {
    try {
      final messageDetailDto = await _remoteDataSource.getMessage(
        messageId,
        includePreSignedUrls: includePreSignedUrls,
      );
      final message = messageDetailDto.toDomain();

      return success(message);
    } on ServerException catch (e) {
      _logger.e('Server error fetching message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on FormatException catch (e) {
      _logger.w('Invalid message data from API: ${e.message}');
      final serverFailure = ServerFailure(
        statusCode: 422,
        details: 'Invalid message data received from server: ${e.message}',
      );
      return failure<Message>(serverFailure);
    } on Exception catch (e, stack) {
      _logger.e(
        'Unknown error fetching message - Exception caught: ${e.runtimeType}: $e',
        stackTrace: stack,
      );
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<Message>>> getMessagesFromConversations({
    required Map<String, DateTime?> conversationCursors,
    int count = 50,
  }) async {
    try {
      final allMessages = <Message>[];

      // Clear cache for conversations that are no longer selected
      // This ensures we don't show stale data when switching conversations
      final cachedConversationIds = _cachedMessages.keys.toSet();
      final requestedConversationIds = conversationCursors.keys.toSet();
      final removedConversations = cachedConversationIds.difference(requestedConversationIds);
      removedConversations.forEach(_cachedMessages.remove);

      // Fetch messages from each conversation using recent endpoint
      for (final entry in conversationCursors.entries) {
        final conversationId = entry.key;
        final beforeTimestamp = entry.value;

        try {
          final result = await getRecentMessages(
            conversationId: conversationId,
            count: count,
            beforeTimestamp: beforeTimestamp,
          );

          if (result.isSuccess) {
            final messages = result.valueOrNull!;
            allMessages.addAll(messages);
          } else {
            _logger.w('Failed to fetch messages from $conversationId: ${result.failureOrNull}');
          }
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
  }

  /// Clears all message cache
  void clearCache() {
    _cachedMessages.clear();
  }
}
