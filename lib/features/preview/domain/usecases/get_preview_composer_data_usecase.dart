import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class GetPreviewComposerDataUsecase {
  GetPreviewComposerDataUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  /// Fetches all data needed for the preview composer screen
  ///
  /// [conversationId] - The conversation to preview
  /// [messageIds] - List of 3-5 message IDs selected by user
  ///
  /// Returns PreviewComposerData with conversation details, messages, and initial metadata
  Future<Result<PreviewComposerData>> call({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    _logger.i('Fetching preview composer data for conversation: $conversationId');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate message count
    if (messageIds.length < 3 || messageIds.length > 5) {
      _logger.w('Invalid message count: ${messageIds.length}');
      return failure(const UnknownFailure(
        details: 'Please select between 3 and 5 messages',
      ));
    }

    return _repository.getPreviewComposerData(
      conversationId: conversationId,
      messageIds: messageIds,
    );
  }
}
