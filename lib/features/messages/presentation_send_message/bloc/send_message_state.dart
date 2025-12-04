import 'package:equatable/equatable.dart';

/// States for SendMessageBloc
sealed class SendMessageState extends Equatable {
  const SendMessageState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no action taken
class SendMessageInitial extends SendMessageState {
  const SendMessageInitial();
}

/// Sending message in progress
class SendMessageInProgress extends SendMessageState {
  const SendMessageInProgress();
}

/// Message sent successfully
class SendMessageSuccess extends SendMessageState {
  const SendMessageSuccess({
    required this.messageId,
    required this.createdAt,
  });

  final String messageId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [messageId, createdAt];
}

/// Error sending message
class SendMessageError extends SendMessageState {
  const SendMessageError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
