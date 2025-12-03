import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Result of fetching messages from conversations with pagination info
class MessagesWithPagination {
  const MessagesWithPagination({
    required this.messages,
    required this.hasMoreMessages,
  });

  final List<Message> messages;
  final bool hasMoreMessages;
}

/// Use case for fetching messages from multiple conversations
@injectable
class GetMessagesFromConversationsUsecase {
  const GetMessagesFromConversationsUsecase(
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Fetches messages from multiple conversations, merged and sorted by date
  ///
  /// [conversationCursors] - Map of conversation ID to the last loaded message timestamp (or null for first page)
  /// [count] - Number of messages to fetch per conversation (default: 50)
  ///
  /// Returns merged list sorted by createdAt (newest first) with pagination info
  Future<Result<MessagesWithPagination>> call({
    required Map<String, DateTime?> conversationCursors,
    int count = 50,
  }) async {
    try {
      final allMessages = <Message>[];
      final conversationResults = <String, int>{}; // conversationId -> messagesReceived

      // Fetch messages from each conversation using recent endpoint
      for (final entry in conversationCursors.entries) {
        final conversationId = entry.key;
        final beforeTimestamp = entry.value ?? DateTime.now(); // Use current time if null

        try {
          final result = await _messageRepository.getRecentMessages(
            conversationId: conversationId,
            count: count,
            beforeTimestamp: beforeTimestamp,
          );

          if (result.isSuccess) {
            final messages = result.valueOrNull!;
            allMessages.addAll(messages);
            conversationResults[conversationId] = messages.length;
          } else {
            _logger.w('Failed to fetch messages from $conversationId: ${result.failureOrNull}');
            conversationResults[conversationId] = 0; // Treat as no messages received
          }
        } on Exception catch (e) {
          // Log warning but continue with other conversations
          _logger.e('Failed to fetch messages from $conversationId: $e');
          conversationResults[conversationId] = 0; // Treat as no messages received
        }
      }

      // Filter out deleted and inactive messages
      final activeMessages = allMessages.where((message) {
        // Filter out messages that have been deleted or are not active
        return message.deletedAt == null && message.status.toLowerCase() == 'active';
      }).toList();

      // Determine if there are more messages available
      // If ANY conversation returned exactly 'count' messages, there might be more
      // Only if ALL conversations returned fewer than 'count' messages, there are no more
      final hasMoreMessages = conversationResults.values.any((received) => received >= count);

      // Sort all messages by date (newest first)
      activeMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return success(MessagesWithPagination(
        messages: activeMessages,
        hasMoreMessages: hasMoreMessages,
      ));
    } on Exception catch (e, stack) {
      _logger.e('Error fetching messages from multiple conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
