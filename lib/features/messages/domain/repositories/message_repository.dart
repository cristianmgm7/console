import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';

/// Repository interface for message operations
abstract class MessageRepository {
  /// Fetches recent messages for a conversation using cursor-based pagination
  /// [conversationId] - The conversation/channel ID
  /// [count] - Number of messages to fetch (default: 50)
  /// [beforeTimestamp] - Optional timestamp to fetch messages before (for pagination)
  /// Returns messages sorted by createdAt (newest first)
  Future<Result<List<Message>>> getRecentMessages({
    required String conversationId,
    int count = 50,
    DateTime? beforeTimestamp,
  });

  /// Fetches a single message by ID
  Future<Result<Message>> getMessage(String messageId, {bool includePreSignedUrls = false});
}
