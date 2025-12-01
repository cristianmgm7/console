import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';

/// Abstract interface for voice memo remote data operations
abstract class VoiceMemoRemoteDataSource {
  /// Fetches voice memos from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<VoiceMemoDto>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  });
}
