import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches all conversations for a workspace
  Future<Result<List<Conversation>>> getConversations(String workspaceId);

  /// Fetches recent channels with pagination and workspace filtering.
  ///
  /// Note: workspace filtering is performed client-side based on the DTO field
  /// `workspace_guid`.
  ///
  /// - [workspaceId]: filter conversations by this workspace
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
