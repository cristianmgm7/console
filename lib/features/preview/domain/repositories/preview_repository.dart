import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';

/// Repository for preview operations
abstract class PreviewRepository {
  /// Publishes a preview (mock operation for now)
  /// Returns generated preview URL
  Future<Result<String>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  });
}
