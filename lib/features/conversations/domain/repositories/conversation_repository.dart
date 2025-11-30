import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches all conversations for a workspace
  Future<Result<List<Conversation>>> getConversations(String workspaceId);

  /// Fetches a single conversation by ID
  Future<Result<Conversation>> getConversation(String conversationId);
}
