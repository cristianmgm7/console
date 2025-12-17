import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/conversations/data/dtos/conversation_dto.dart';

/// Abstract interface for conversation remote data operations
abstract class ConversationRemoteDataSource {
  /// Fetches recent channels for the current user (across all workspaces) using
  /// cursor-based pagination.
  ///
  /// Endpoint: POST /channels/recent
  /// Request Body: {"limit": int, "direction": "older"|"newer", "date": "ISO8601", "includeDeleted": bool}
  ///
  /// - [limit]: number of channels to fetch
  /// - [direction]: "older" or "newer"
  /// - [date]: ISO8601 timestamp cursor (optional)
  /// - [includeDeleted]: whether to include deleted channels
  ///
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getRecentChannels({
    required int limit,
    String? date,
    String direction = 'older',
    bool includeDeleted = false,
  });

  /// Fetches a single conversation by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<ConversationDto> getConversation(String conversationId);
}
