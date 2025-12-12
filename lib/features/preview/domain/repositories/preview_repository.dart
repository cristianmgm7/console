import 'package:carbon_voice_console/core/utils/result.dart';

/// Repository for preview operations
// ignore: one_member_abstracts
abstract class PreviewRepository {
  /// Publishes a preview (mock operation for now)
  /// Returns generated preview URL
  Future<Result<String>> publishPreview({
    required String conversationId,
    required List<String> messageIds,
    required String title,
    required String description,
  });
}
