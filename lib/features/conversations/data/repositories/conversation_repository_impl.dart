import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/data/mappers/conversation_dto_mapper.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: ConversationRepository)
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource, this._logger);

  final ConversationRemoteDataSource _remoteDataSource;
  final Logger _logger;

  @override
  Future<Result<List<Conversation>>> getRecentConversations({
    required String workspaceId,
    required int limit,
    String? beforeDate,
  }) async {
    try {
      // For the first page, use "now" to fetch the most recent channels.
      // Use UTC ISO8601 ("...Z") to match the common backend expectation for date-time cursors.
      final dateToUse = beforeDate ?? DateTime.now().toUtc().toIso8601String();

      // Use the new derived endpoint with workspace_guid as source
      final conversationDtos = await _remoteDataSource.getRecentChannelsBySource(
        sourceType: 'workspace_id',
        sourceValue: workspaceId,
        limit: limit,
        date: dateToUse,
      );

      final conversations = conversationDtos.map((dto) => dto.toDomain()).toList();

      return success(conversations);
    } on ServerException catch (e) {
      _logger.e('Server error fetching recent conversations', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching recent conversations', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching recent conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async {
    try {
      final conversationDto = await _remoteDataSource.getConversation(conversationId);
      final conversation = conversationDto.toDomain();
      return success(conversation);
    } on ServerException catch (e) {
      _logger.e('Server error fetching conversation', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching conversation', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching conversation', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
