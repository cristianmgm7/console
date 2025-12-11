import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
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
  /// [metadata] - User-entered preview metadata
  /// [messageIds] - List of selected message IDs
  ///
  /// Returns generated preview URL on success
  Future<Result<String>> call({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    _logger.i('Publishing preview for conversation: $conversationId');
    _logger.d('Metadata: ${metadata.title} - ${metadata.description}');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate
    if (metadata.title.trim().isEmpty) {
      return failure(const UnknownFailure(details: 'Title is required'));
    }

    if (metadata.description.trim().isEmpty) {
      return failure(const UnknownFailure(details: 'Description is required'));
    }

    if (messageIds.length < 3 || messageIds.length > 5) {
      return failure(
        const UnknownFailure(
          details: 'Please select between 3 and 5 messages',
        ),
      );
    }

    return _repository.publishPreview(
      conversationId: conversationId,
      metadata: metadata,
      messageIds: messageIds,
    );
  }
}
