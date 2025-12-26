import 'package:equatable/equatable.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionLoaded extends SessionState {
  final List<AgentChatSession> sessions;
  final String? selectedSessionId;

  const SessionLoaded({
    required this.sessions,
    this.selectedSessionId,
  });

  @override
  List<Object?> get props => [sessions, selectedSessionId];

  SessionLoaded copyWith({
    List<AgentChatSession>? sessions,
    String? selectedSessionId,
  }) {
    return SessionLoaded(
      sessions: sessions ?? this.sessions,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
    );
  }

  AgentChatSession? get selectedSession {
    if (selectedSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == selectedSessionId);
    } catch (e) {
      return null;
    }
  }
}

class SessionError extends SessionState {
  final String message;

  const SessionError(this.message);

  @override
  List<Object?> get props => [message];
}
