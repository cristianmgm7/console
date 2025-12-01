import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/voice_memos/data/datasources/voice_memo_remote_datasource.dart';
import 'package:carbon_voice_console/features/voice_memos/data/mappers/voice_memo_dto_mapper.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/repositories/voice_memo_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: VoiceMemoRepository)
class VoiceMemoRepositoryImpl implements VoiceMemoRepository {
  VoiceMemoRepositoryImpl(this._remoteDataSource, this._logger);

  final VoiceMemoRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: workspace_folder key -> voice memos (sorted)
  final Map<String, List<VoiceMemo>> _cachedVoiceMemos = {};

  String _buildCacheKey({String? workspaceId, String? folderId}) {
    return '${workspaceId ?? 'all'}_${folderId ?? 'all'}';
  }

  @override
  Future<Result<List<VoiceMemo>>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  }) async {
    try {
      final cacheKey = _buildCacheKey(workspaceId: workspaceId, folderId: folderId);

      // Return cached voice memos if available
      if (_cachedVoiceMemos.containsKey(cacheKey)) {
        _logger.d('Returning cached voice memos for key: $cacheKey');
        return success(_cachedVoiceMemos[cacheKey]!);
      }

      final voiceMemoDtos = await _remoteDataSource.getVoiceMemos(
        workspaceId: workspaceId,
        folderId: folderId,
        limit: limit,
        date: date,
        direction: direction,
        sortDirection: sortDirection,
        includeDeleted: includeDeleted,
      );

      final voiceMemos = voiceMemoDtos.map((dto) => dto.toDomain()).toList();

      // Sort by date (newest first) if DESC, oldest first if ASC
      if (sortDirection == 'DESC') {
        voiceMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        voiceMemos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      // Cache the result
      _cachedVoiceMemos[cacheKey] = voiceMemos;

      _logger.d('Fetched and cached ${voiceMemos.length} voice memos');
      return success(voiceMemos);
    } on ServerException catch (e) {
      _logger.e('Server error fetching voice memos', error: e);
      return failure(
        ServerFailure(statusCode: e.statusCode, details: e.message),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error fetching voice memos', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching voice memos', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  void clearCache() {
    _cachedVoiceMemos.clear();
    _logger.d('Voice memo cache cleared');
  }
}
