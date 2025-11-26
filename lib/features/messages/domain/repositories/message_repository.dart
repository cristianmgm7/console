import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';

/// Repository interface for message operations
abstract class MessageRepository {
  /// Fetches messages for a conversation using sequential pagination
  /// [conversationId] - The conversation/channel ID
  /// [start] - Starting sequence number (0-based)
  /// [count] - Number of messages to fetch
  Future<Result<List<Message>>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  });

  /// Fetches a single message by ID
  Future<Result<Message>> getMessage(String messageId);


  /// Fetches messages from multiple conversations, merged and sorted by date
  /// [conversationIds] - Set of conversation IDs to fetch from
  /// [count] - Number of messages to fetch per conversation (default: 50)
  /// Returns merged list sorted by createdAt (newest first)
  Future<Result<List<Message>>> getMessagesFromConversations({
    required Set<String> conversationIds,
    int count = 50,
  }); 
}
