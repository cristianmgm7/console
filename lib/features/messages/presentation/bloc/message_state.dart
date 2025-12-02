import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

sealed class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {
  const MessageInitial();
}

class MessageLoading extends MessageState {
  const MessageLoading();
}

class MessageLoaded extends MessageState {
  const MessageLoaded({
    required this.messages,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.oldestMessageTimestamp,
  });
  final List<MessageUiModel> messages;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final DateTime? oldestMessageTimestamp;

  @override
  List<Object?> get props => [messages, isLoadingMore, hasMoreMessages, oldestMessageTimestamp];

  MessageLoaded copyWith({
    List<MessageUiModel>? messages,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    DateTime? oldestMessageTimestamp,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      oldestMessageTimestamp: oldestMessageTimestamp ?? this.oldestMessageTimestamp,
    );
  }
}

class MessageError extends MessageState {
  const MessageError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class MessageDetailLoaded extends MessageState {
  const MessageDetailLoaded({
    required this.message,
    required this.user,
  });
  final MessageUiModel message;
  final User? user;

  @override
  List<Object?> get props => [message, user];
}
