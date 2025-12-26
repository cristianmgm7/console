import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'session_event.dart';
import 'session_state.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_session_repository.dart';

@injectable
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AgentSessionRepository _repository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  SessionBloc(this._repository, this._logger) : super(const SessionInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateNewSession>(_onCreateNewSession);
    on<SelectSession>(_onSelectSession);
    on<DeleteSession>(_onDeleteSession);
    on<UpdateSessionPreview>(_onUpdateSessionPreview);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await _repository.loadSessions();

    result.fold(
      onSuccess: (sessions) {
        emit(SessionLoaded(sessions: sessions));
      },
      onFailure: (failure) {
        _logger.e('Failed to load sessions', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to load sessions'));
      },
    );
  }

  Future<void> _onCreateNewSession(
    CreateNewSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final sessionId = _uuid.v4();

    final result = await _repository.createSession(sessionId);

    result.fold(
      onSuccess: (newSession) {
        final updatedSessions = [newSession, ...currentState.sessions];
        emit(SessionLoaded(
          sessions: updatedSessions,
          selectedSessionId: sessionId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to create session', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to create session'));
        // Restore previous state
        emit(currentState);
      },
    );
  }

  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    emit(currentState.copyWith(selectedSessionId: event.sessionId));
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final result = await _repository.deleteSession(event.sessionId);

    result.fold(
      onSuccess: (_) {
        final updatedSessions = currentState.sessions
            .where((s) => s.id != event.sessionId)
            .toList();

        String? newSelectedId = currentState.selectedSessionId;
        if (newSelectedId == event.sessionId) {
          newSelectedId = updatedSessions.isNotEmpty ? updatedSessions.first.id : null;
        }

        emit(SessionLoaded(
          sessions: updatedSessions,
          selectedSessionId: newSelectedId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to delete session', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to delete session'));
        emit(currentState);
      },
    );
  }

  Future<void> _onUpdateSessionPreview(
    UpdateSessionPreview event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final updatedSessions = currentState.sessions.map((session) {
      if (session.id == event.sessionId) {
        return session.copyWith(
          lastMessagePreview: event.preview,
          lastUpdateTime: DateTime.now(),
        );
      }
      return session;
    }).toList();

    // Sort by last update time (most recent first)
    updatedSessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));

    emit(currentState.copyWith(sessions: updatedSessions));
  }
}
