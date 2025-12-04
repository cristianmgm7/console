import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/mappers/message_dto_mapper.dart';
import 'package:carbon_voice_console/features/messages/data/mappers/send_message_request_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
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
  Future<Result<Message>> sendMessage(SendMessageRequest request) async {
    try {
      final requestDto = request.toDto();
      final messageDto = await _remoteDataSource.sendMessage(requestDto);

      // Convert DTO to domain entity using existing mapper
      final message = messageDto.toDomain();

      // Invalidate cache for the conversation to reflect new message
      clearCacheForConversation(request.channelId);

      return success(message);
    } on ServerException catch (e) {
      _logger.e('Server error sending message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error sending message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error sending message', error: e, stackTrace: stack);
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
