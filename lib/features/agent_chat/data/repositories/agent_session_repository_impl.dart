import 'dart:convert';

import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/session_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/session_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_session_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AgentSessionRepository)
class AgentSessionRepositoryImpl implements AgentSessionRepository {

  AgentSessionRepositoryImpl(
    this._apiService,
    this._storage,
    this._logger,
  );
  final AdkApiService _apiService;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  static const _sessionsKey = 'agent_chat_sessions';

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'test_user'; // Placeholder - matches ADK test user
  }

  @override
  Future<Result<List<AgentChatSession>>> loadSessions() async {
    try {
      // Load from local storage first for offline access
      final sessionsJson = await _storage.read(key: _sessionsKey);

      if (sessionsJson == null) {
        return success([]);
      }

      final sessionsList = jsonDecode(sessionsJson) as List;
      final sessions = sessionsList
          .map((json) => SessionDto.fromJson(json as Map<String, dynamic>).toDomain())
          .toList();

      // Sort by last update time
      sessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));

      return success(sessions);
    } on StorageException catch (e) {
      _logger.e('Error loading sessions', error: e);
      return failure(const StorageFailure(details: 'Failed to load sessions'));
    }
  }

  @override
  Future<Result<AgentChatSession>> createSession(String sessionId) async {
    try {
      final sessionDto = await _apiService.createSession(
        userId: _userId,
        sessionId: sessionId,
      );

      final session = sessionDto.toDomain();

      // Save to local storage
      await saveSessionLocally(session);

      return success(session);
    } on ServerException catch (e) {
      _logger.e('Server error creating session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error creating session', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e) {
      _logger.e('Unexpected error creating session', error: e);
      return failure(const UnknownFailure(details: 'Failed to create session'));
    }
  }

  @override
  Future<Result<AgentChatSession>> getSession(String sessionId) async {
    try {
      final sessionDto = await _apiService.getSession(
        userId: _userId,
        sessionId: sessionId,
      );

      final session = sessionDto.toDomain();

      return success(session);
    } on ServerException catch (e) {
      _logger.e('Server error getting session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error getting session', error: e);
      return failure(NetworkFailure(details: e.message));
    // ignore: avoid_catches_without_on_clauses
    } on Exception catch (e) {
      _logger.e('Unexpected error getting session', error: e);
      return failure(const UnknownFailure(details: 'Failed to get session'));
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _apiService.deleteSession(
        userId: _userId,
        sessionId: sessionId,
      );

      // Remove from local storage
      final sessionsResult = await loadSessions();
      final sessions = sessionsResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => <AgentChatSession>[],
      );

      final updatedSessions = sessions.where((s) => s.id != sessionId).toList();

      final sessionsJson = jsonEncode(
        updatedSessions.map((s) => <String, dynamic>{
          'id': s.id,
          'appName': s.appName,
          'userId': s.userId,
          'state': s.state,
          'events': <dynamic>[],
          'lastUpdateTime': s.lastUpdateTime.millisecondsSinceEpoch / 1000,
        }).toList(),
      );

      await _storage.write(key: _sessionsKey, value: sessionsJson);

      return success(null);
    } on ServerException catch (e) {
      _logger.e('Server error deleting session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error deleting session', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error deleting session', error: e);
      return failure(const UnknownFailure(details: 'Failed to delete session'));
    }
  }

  @override
  Future<Result<void>> saveSessionLocally(AgentChatSession session) async {
    try {
      final sessionsResult = await loadSessions();
      final sessions = sessionsResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => <AgentChatSession>[],
      );

      // Add or update session
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      final sessionsJson = jsonEncode(
        sessions.map((s) => <String, dynamic>{
          'id': s.id,
          'appName': s.appName,
          'userId': s.userId,
          'state': s.state,
          'events': <dynamic>[],
          'lastUpdateTime': s.lastUpdateTime.millisecondsSinceEpoch / 1000,
        }).toList(),
      );

      await _storage.write(key: _sessionsKey, value: sessionsJson);

      return success(null);
    } catch (e) {
      _logger.e('Error saving session locally', error: e);
      return failure(const StorageFailure(details: 'Failed to save session'));
    }
  }
}
