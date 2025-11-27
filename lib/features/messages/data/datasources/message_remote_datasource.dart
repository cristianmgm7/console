import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';

/// Abstract interface for message remote data operations
abstract class MessageRemoteDataSource {
  /// Fetches messages using sequential pagination from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageDto>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  });

  /// Fetches a single message by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageDto> getMessage(String messageId);

}
