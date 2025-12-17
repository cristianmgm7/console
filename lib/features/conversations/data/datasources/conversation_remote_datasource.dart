import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/conversations/data/dtos/conversation_dto.dart';

/// Abstract interface for conversation remote data operations
abstract class ConversationRemoteDataSource {
  /// Fetches recent channels using cursor-based pagination with source filtering.
  ///
  /// Uses the /channels/recent/derived/{source_type}/{source_value} endpoint.
  ///
  /// - [sourceType]: type of source filter (e.g., "workspace_guid")
  /// - [sourceValue]: value for the source filter (e.g., workspace ID)
  /// - [limit]: number of channels to fetch
  /// - [direction]: "older" or "newer"
  /// - [date]: ISO8601 timestamp for pagination cursor
  /// - [includeDeleted]: whether to include deleted channels
  ///
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getRecentChannelsBySource({
    required String sourceType,
    required String sourceValue,
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
