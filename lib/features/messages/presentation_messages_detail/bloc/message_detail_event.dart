part of 'message_detail_bloc.dart';

sealed class MessageDetailEvent extends Equatable {
  const MessageDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessageDetail extends MessageDetailEvent {
  const LoadMessageDetail(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}
