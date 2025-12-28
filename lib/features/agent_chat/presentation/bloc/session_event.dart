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

  const SelectSession(this.sessionId);
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class DeleteSession extends SessionEvent {

  const DeleteSession(this.sessionId);
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class UpdateSessionPreview extends SessionEvent {

  const UpdateSessionPreview(this.sessionId, this.preview);
  final String sessionId;
  final String preview;

  @override
  List<Object?> get props => [sessionId, preview];
}
