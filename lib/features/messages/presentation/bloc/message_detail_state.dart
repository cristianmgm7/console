part of 'message_detail_bloc.dart';

sealed class MessageDetailState extends Equatable {
  const MessageDetailState();

  @override
  List<Object?> get props => [];
}

class MessageDetailInitial extends MessageDetailState {
  const MessageDetailInitial();
}

class MessageDetailLoading extends MessageDetailState {
  const MessageDetailLoading();
}

class MessageDetailLoaded extends MessageDetailState {
  const MessageDetailLoaded({
    required this.message,
    this.user,
  });

  final MessageUiModel message;
  final User? user;

  @override
  List<Object?> get props => [message, user];
}

class MessageDetailError extends MessageDetailState {
  const MessageDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
