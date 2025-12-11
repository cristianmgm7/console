import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: PreviewRepository)
class PreviewRepositoryImpl implements PreviewRepository {
  PreviewRepositoryImpl(
    this._conversationRepository,
    this._messageRepository,
    this._logger,
  );

  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  @override
  Future<Result<PreviewComposerData>> getPreviewComposerData({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Fetching preview composer data');
      _logger.d('Conversation ID: $conversationId');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

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
        return failure(const UnknownFailure(
          details: 'Failed to fetch conversation',
        ));
      }

      // Fetch all selected messages in parallel
      final messageFutures = messageIds.map((messageId) =>
        _messageRepository.getMessage(messageId)).toList();

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
        return failure(const UnknownFailure(
          details: 'Could not load enough messages for preview',
        ));
      }

      // Create initial metadata from conversation
      final initialMetadata = PreviewMetadata(
        title: conversation.name,
        description: conversation.description ?? '',
        coverImageUrl: conversation.imageUrl,
      );

      final composerData = PreviewComposerData(
        conversation: conversation,
        selectedMessages: messages,
        initialMetadata: initialMetadata,
      );

      _logger.i('Successfully fetched preview composer data');
      return success(composerData);
    } on Failure<PreviewComposerData> catch (failure) {
      // Already logged in fold
      return failure;
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching preview data', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<String>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Mock publishing preview');
      _logger.d('Conversation: $conversationId');
      _logger.d('Title: ${metadata.title}');
      _logger.d('Description: ${metadata.description}');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

      // Simulate network delay
      await Future<void>.delayed(const Duration(seconds: 1));

      // Generate mock preview URL
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mockUrl = 'https://carbonvoice.app/preview/demo_$timestamp';

      _logger.i('Mock preview published: $mockUrl');

      return success(mockUrl);
    } on Exception catch (e, stack) {
      _logger.e('Error publishing preview', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
