import 'package:equatable/equatable.dart';

class MessageCompositionState extends Equatable {
  const MessageCompositionState({
    this.isVisible = false,
    this.workspaceId,
    this.channelId,
    this.replyToMessageId,
  });

  final bool isVisible;
  final String? workspaceId;
  final String? channelId;
  final String? replyToMessageId;

  bool get isReply => replyToMessageId != null;
  bool get canCompose => workspaceId != null && channelId != null;

  MessageCompositionState copyWith({
    bool? isVisible,
    String? workspaceId,
    String? channelId,
    String? replyToMessageId,
  }) {
    return MessageCompositionState(
      isVisible: isVisible ?? this.isVisible,
      workspaceId: workspaceId ?? this.workspaceId,
      channelId: channelId ?? this.channelId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  MessageCompositionState copyWithNullableReply({
    String? replyToMessageId,
  }) {
    return MessageCompositionState(
      isVisible: isVisible,
      workspaceId: workspaceId,
      channelId: channelId,
      replyToMessageId: replyToMessageId,
    );
  }

  @override
  List<Object?> get props => [isVisible, workspaceId, channelId, replyToMessageId];
}
