import 'package:carbon_voice_console/features/messages/data/models/message_model.dart';

/// Abstract interface for message remote data operations
abstract class MessageRemoteDataSource {
  /// Fetches messages using sequential pagination from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  });

  /// Fetches a single message by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageModel> getMessage(String messageId);

  /// Fetches recent messages from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageModel>> getRecentMessages({
    required String conversationId,
    int count = 50,
  });
}

