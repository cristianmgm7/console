import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: PreviewRepository)
class PreviewRepositoryImpl implements PreviewRepository {
  PreviewRepositoryImpl(this._logger);

  final Logger _logger;

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
