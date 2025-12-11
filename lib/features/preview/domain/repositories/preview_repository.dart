import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';

/// Repository for preview operations
abstract class PreviewRepository {
  /// Fetches all data needed for the preview composer screen
  Future<Result<PreviewComposerData>> getPreviewComposerData({
    required String conversationId,
    required List<String> messageIds,
  });

  /// Publishes a preview (mock operation for now)
  /// Returns generated preview URL
  Future<Result<String>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  });
}
