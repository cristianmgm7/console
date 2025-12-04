import 'package:equatable/equatable.dart';

/// Events for SendMessageBloc
sealed class SendMessageEvent extends Equatable {
  const SendMessageEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send a new message
class SendMessage extends SendMessageEvent {
  const SendMessage({
    required this.text,
    required this.channelId,
    required this.workspaceId,
    this.replyToMessageId,
  });

  final String text;
  final String channelId;
  final String workspaceId;
  final String? replyToMessageId;

  @override
  List<Object?> get props => [text, channelId, workspaceId, replyToMessageId];
}

/// Event to reset the send message state
class ResetSendMessage extends SendMessageEvent {
  const ResetSendMessage();
}
