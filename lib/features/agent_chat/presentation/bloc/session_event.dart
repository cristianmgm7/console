import 'package:equatable/equatable.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends SessionEvent {
  const LoadSessions();
}

class CreateNewSession extends SessionEvent {
  const CreateNewSession();
}

class SelectSession extends SessionEvent {
  final String sessionId;

  const SelectSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class DeleteSession extends SessionEvent {
  final String sessionId;

  const DeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class UpdateSessionPreview extends SessionEvent {
  final String sessionId;
  final String preview;

  const UpdateSessionPreview(this.sessionId, this.preview);

  @override
  List<Object?> get props => [sessionId, preview];
}
