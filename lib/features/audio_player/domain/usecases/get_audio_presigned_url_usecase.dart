import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case for fetching pre-signed audio URL for playback
@injectable
class GetAudioPreSignedUrlUsecase {
  const GetAudioPreSignedUrlUsecase(
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Fetches the pre-signed URL for a message's audio
  ///
  /// [messageId] - The ID of the message to fetch audio for
  ///
  /// Returns a Result containing the pre-signed URL string on success,
  /// or a Failure if the message has no audio or the fetch fails
  Future<Result<String>> call(String messageId) async {
    try {
      _logger.d('Fetching pre-signed URL for message: $messageId');

      // Fetch message with pre-signed URLs
      final result = await _messageRepository.getMessage(
        messageId,
        includePreSignedUrls: true,
      );

      return result.fold(
        onSuccess: (message) {
          // Check if message has audio
          if (message.audioModels.isEmpty) {
            _logger.w('Message $messageId has no audio models');
            return failure<String>(
              const UnknownFailure(details: 'Message has no audio'),
            );
          }

          // Get the first audio model (typically MP3)
          final audioModel = message.audioModels.first;

          // Check if pre-signed URL exists
          if (audioModel.presignedUrl == null || audioModel.presignedUrl!.isEmpty) {
            _logger.e('Message $messageId audio has no pre-signed URL');
            return failure<String>(
              const UnknownFailure(
                details: 'Audio pre-signed URL not available',
              ),
            );
          }

          _logger.d('Successfully fetched pre-signed URL for message $messageId');
          return success<String>(audioModel.presignedUrl!);
        },
        onFailure: (failureResult) {
          _logger.e('Failed to fetch message $messageId: ${failureResult.failureOrNull}');
          return failure<String>(
            failureResult.failureOrNull ?? const UnknownFailure(details: 'Failed to fetch message'),
          );
        },
      );
    } on Exception catch (e, stack) {
      _logger.e(
        'Unexpected error fetching pre-signed URL for message $messageId',
        error: e,
        stackTrace: stack,
      );
      return failure(
        UnknownFailure(details: 'Failed to fetch pre-signed URL: $e'),
      );
    }
  }
}
