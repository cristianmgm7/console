import 'package:equatable/equatable.dart';

/// Domain entity for composing a message to send
class SendMessageRequest extends Equatable {
  const SendMessageRequest({
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



