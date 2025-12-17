import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches recent channels with pagination filtered by workspace.
  ///
  /// Uses the /channels/recent/derived endpoint with workspace_guid as source.
  ///
  /// - [workspaceId]: workspace to filter conversations by
  /// - [limit]: number of conversations to fetch
  /// - [beforeDate]: ISO8601 timestamp to fetch conversations before (pagination cursor)
  Future<Result<List<Conversation>>> getRecentConversations({
    required String workspaceId,
    required int limit,
    String? beforeDate,
  });

  /// Fetches a single conversation by ID
  Future<Result<Conversation>> getConversation(String conversationId);
}
