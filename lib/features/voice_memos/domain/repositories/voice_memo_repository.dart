import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';

/// Repository interface for voice memo operations
abstract class VoiceMemoRepository {
  /// Fetches voice memos from the API
  ///
  /// Parameters:
  /// - [workspaceId]: Optional workspace filter
  /// - [folderId]: Optional folder filter
  /// - [limit]: Number of voice memos to fetch (default: 200)
  /// - [date]: Reference date for pagination
  /// - [direction]: Pagination direction ('older' or 'newer')
  /// - [sortDirection]: Sort order ('ASC' or 'DESC')
  /// - [includeDeleted]: Whether to include deleted memos (default: true)
  Future<Result<List<VoiceMemo>>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  });

  /// Clears the voice memo cache
  void clearCache();
}
