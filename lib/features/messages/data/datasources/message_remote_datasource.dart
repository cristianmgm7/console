import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_detail_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/send_message_request_dto.dart';

/// Abstract interface for message remote data operations
abstract class MessageRemoteDataSource {
  /// Fetches recent messages for a conversation using cursor-based pagination
  /// [conversationId] - The conversation/channel ID
  /// [count] - Number of messages to fetch (default: 50)
  /// [direction] - "older" or "newer" (default: "older")
  /// [beforeTimestamp] - Optional ISO8601 timestamp to fetch messages before this time (for pagination)
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageDto>> getRecentMessages({
    required String conversationId,
    int count = 50,
    String direction = 'older',
    String? beforeTimestamp,
  });

  /// Fetches a single message by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageDetailDto> getMessage(String messageId, {bool includePreSignedUrls = false});

  /// Sends a new message or reply
  /// Returns the created message as MessageDto
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageDto> sendMessage(SendMessageRequestDto request);

}
