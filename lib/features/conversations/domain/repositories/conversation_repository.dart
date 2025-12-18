import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches recent channels with pagination.
  ///
  /// Uses the global /channels/recent endpoint which returns conversations across all workspaces.
  /// Note: Filtering by workspace is done at the bloc level since the API doesn't support it.
  ///
  /// - [workspaceId]: kept for interface compatibility but not used for filtering (filtering done in bloc)
  /// - [limit]: number of conversations to fetch from the API
  /// - [beforeDate]: ISO8601 timestamp to fetch conversations before (pagination cursor)
  Future<Result<List<Conversation>>> getRecentConversations({
    required String workspaceId,
    required int limit,
    String? beforeDate,
  });

  /// Fetches a single conversation by ID
  Future<Result<Conversation>> getConversation(String conversationId);
}
