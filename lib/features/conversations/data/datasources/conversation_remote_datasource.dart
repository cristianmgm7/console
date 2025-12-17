import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/conversations/data/dtos/conversation_dto.dart';

/// Abstract interface for conversation remote data operations
abstract class ConversationRemoteDataSource {
  /// Fetches all conversations for a workspace from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getConversations(String workspaceId);

  /// Fetches recent channels using cursor-based pagination.
  ///
  /// - [limit]: number of channels to fetch
  /// - [direction]: "older" or "newer"
  /// - [date]: ISO8601 timestamp for pagination cursor
  /// - [includeDeleted]: whether to include deleted channels
  ///
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getRecentChannels({
    required int limit,
    required String date,
    String direction = 'older',
    bool includeDeleted = false,
  });

  /// Fetches a single conversation by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<ConversationDto> getConversation(String conversationId);
}
