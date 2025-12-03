import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/dtos/conversation_dto.dart';

/// Abstract interface for conversation remote data operations
abstract class ConversationRemoteDataSource {
  /// Fetches all conversations for a workspace from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getConversations(String workspaceId);

  /// Fetches a single conversation by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<ConversationDto> getConversation(String conversationId);
}
