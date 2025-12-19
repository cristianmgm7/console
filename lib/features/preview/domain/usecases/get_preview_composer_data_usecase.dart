import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Result containing conversation, selected messages, and parent messages
class EnrichedPreviewComposerData {
  const EnrichedPreviewComposerData({
    required this.conversation,
    required this.selectedMessages,
    required this.parentMessages,
  });

  final Conversation conversation;
  final List<Message> selectedMessages;
  final List<Message> parentMessages;
}


@injectable
class GetPreviewComposerDataUsecase {
  GetPreviewComposerDataUsecase(
    this._conversationRepository,
    this._messageRepository,
    this._logger,
  );

  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Fetches all data needed for the preview composer screen
  ///
  /// [conversationId] - The conversation to preview
  /// [messageIds] - List of 3-10 message IDs selected by user
  ///
  /// Returns EnrichedPreviewComposerData with conversation, selected messages, and parent messages
  Future<Result<EnrichedPreviewComposerData>> call({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Fetching preview composer data');
      _logger.d('Conversation ID: $conversationId');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

      // Validate message count
      if (messageIds.length < 3 || messageIds.length > 10) {
        _logger.w('Invalid message count: ${messageIds.length}');
        return failure(
          const UnknownFailure(
            details: 'Please select between 3 and 10 messages',
          ),
        );
      }

      // Fetch conversation details
      final conversationResult = await _conversationRepository.getConversation(
        conversationId,
      );

      // Early return if conversation fetch failed
      final conversation = conversationResult.fold(
        onSuccess: (conv) => conv,
        onFailure: (failure) {
          _logger.e('Failed to fetch conversation: ${failure.failure.code}');
          return null;
        },
      );

      if (conversation == null) {
        return failure(
          const UnknownFailure(
            details: 'Failed to fetch conversation',
          ),
        );
      }

      // Fetch all selected messages in parallel with presigned URLs for audio playback
      final messageFutures = messageIds.map(
        (messageId) => _messageRepository.getMessage(messageId, includePreSignedUrls: true),
      ).toList();

      final messageResults = await Future.wait(messageFutures);

      // Extract messages, collecting failures
      final messages = <Message>[];
      for (var i = 0; i < messageResults.length; i++) {
        final result = messageResults[i];
        result.fold(
          onSuccess: (message) {
            messages.add(message);
          },
          onFailure: (failure) {
            _logger.w(
              'Failed to fetch message ${messageIds[i]}: ${failure.failure.code}',
            );
            // Continue fetching other messages even if one fails
          },
        );
      }

      // Ensure we have at least 3 messages
      if (messages.length < 3) {
        _logger.e('Insufficient messages fetched: ${messages.length}');
        return failure(
          const UnknownFailure(
            details: 'Could not load enough messages for preview',
          ),
        );
      }

      // Fetch parent messages for replies
      final parentMessageIds = messages
          .where((message) => message.parentMessageId != null)
          .map((message) => message.parentMessageId!)
          .toSet() // Remove duplicates
          .toList();

      final parentMessageMap = <String, Message>{};
      if (parentMessageIds.isNotEmpty) {
        _logger.d('Fetching ${parentMessageIds.length} parent messages');

        final parentMessageFutures = parentMessageIds.map(
          (parentId) => _messageRepository.getMessage(parentId, includePreSignedUrls: true),
        ).toList();

        final parentMessageResults = await Future.wait(parentMessageFutures);

        for (var i = 0; i < parentMessageResults.length; i++) {
          final result = parentMessageResults[i];
          result.fold(
            onSuccess: (parentMessage) {
              parentMessageMap[parentMessage.id] = parentMessage;
            },
            onFailure: (failure) {
              _logger.w(
                'Failed to fetch parent message ${parentMessageIds[i]}: ${failure.failure.code}',
              );
              // Continue even if parent message fetch fails
            },
          );
        }

        _logger.d('Fetched ${parentMessageMap.length} parent messages');
      }

      // Create user map from conversation collaborators
      final userMap = <String, User>{};

      // Add conversation collaborators as User entities
      if (conversation.collaborators != null) {
        for (final collaborator in conversation.collaborators!) {
          if (collaborator.userGuid != null &&
              collaborator.firstName != null &&
              collaborator.lastName != null) {
            final user = User(
              id: collaborator.userGuid!,
              firstName: collaborator.firstName!,
              lastName: collaborator.lastName!,
              email: '', // Not available from collaborators
              isVerified: false, // Default assumption
              avatarUrl: collaborator.imageUrl,
            );
            userMap[collaborator.userGuid!] = user;
          }
        }
      }

      _logger.d('Created ${userMap.length} user profiles from collaborators');


      final enrichedData = EnrichedPreviewComposerData(
        conversation: conversation,
        selectedMessages: messages,
        parentMessages: parentMessageMap.values.toList(),
      );

      _logger.i('Successfully created preview composer data with ${userMap.length} users from collaborators');
      return success(enrichedData);
    } on Failure<EnrichedPreviewComposerData> catch (failure) {
      // Already logged in fold
      return failure;
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching preview data', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
