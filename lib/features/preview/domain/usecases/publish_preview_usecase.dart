import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PublishPreviewUsecase {
  PublishPreviewUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  /// Publishes a conversation preview (mock operation for now)
  ///
  /// [conversationId] - The conversation being previewed
  /// [messageIds] - List of selected message IDs
  /// [title] - Preview title
  /// [description] - Preview description
  ///
  /// Returns generated preview URL on success
  Future<Result<String>> call({
    required String conversationId,
    required List<String> messageIds,
    required String title,
    required String description,
  }) async {
    _logger.i('Publishing preview for conversation: $conversationId');
    _logger.d('Title: $title');
    _logger.d('Description: $description');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate
    if (messageIds.length < 3 || messageIds.length > 10) {
      return failure(
        const UnknownFailure(
          details: 'Please select between 3 and 10 messages',
        ),
      );
    }

    return _repository.publishPreview(
      conversationId: conversationId,
      messageIds: messageIds,
      title: title,
      description: description,
    );
  }
}
