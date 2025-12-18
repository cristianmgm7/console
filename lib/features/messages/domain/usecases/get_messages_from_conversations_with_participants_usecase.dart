import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Result of fetching messages with participant information
class MessagesWithParticipants {
  const MessagesWithParticipants({
    required this.messages,
    required this.participants,
    required this.hasMoreMessages,
  });

  final List<Message> messages;
  final Map<String, ConversationCollaborator> participants;
  final bool hasMoreMessages;
}

/// Use case for fetching messages from multiple conversations with participant info
@injectable
class GetMessagesFromConversationsWithParticipantsUsecase {
  const GetMessagesFromConversationsWithParticipantsUsecase(
    this._messageRepository,
    this._conversationRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;
  final Logger _logger;

  /// Fetches messages from multiple conversations with participant information
  ///
  /// [conversationCursors] - Map of conversation ID to the last loaded message timestamp
  /// [count] - Number of messages to fetch per conversation (default: 50)
  ///
  /// Returns merged list sorted by createdAt (newest first) with participants and pagination info
  Future<Result<MessagesWithParticipants>> call({
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
      final hasMoreMessages = conversationResults.values.any((received) => received >= count);

      // Sort all messages by date (newest first)
      activeMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Fetch participant information from conversations
      final participantMap = <String, ConversationCollaborator>{};
      final uniqueConversationIds = conversationCursors.keys.toSet();

      // Fetch conversations in parallel to get collaborators
      final conversationFutures = uniqueConversationIds
          .map(
            _conversationRepository.getConversation,
          )
          .toList();

      final conversationFetchResults = await Future.wait(conversationFutures);

      // Extract all collaborators from all conversations
      for (var i = 0; i < conversationFetchResults.length; i++) {
        final result = conversationFetchResults[i];
        final conversationId = uniqueConversationIds.elementAt(i);

        result.fold(
          onSuccess: (conversation) {
            final collaborators = conversation.collaborators ?? [];
            for (final collaborator in collaborators) {
              if (collaborator.userGuid != null) {
                // Add to map, later entries will overwrite earlier ones (same user data)
                participantMap[collaborator.userGuid!] = collaborator;
              }
            }
          },
          onFailure: (failure) {
            _logger.w(
              'Failed to fetch conversation $conversationId for participants: ${failure.failure.code}',
            );
            // Continue without participants from this conversation
          },
        );
      }

      return success(
        MessagesWithParticipants(
          messages: activeMessages,
          participants: participantMap,
          hasMoreMessages: hasMoreMessages,
        ),
      );
    } on Exception catch (e, stack) {
      _logger.e('Error fetching messages with participants', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
