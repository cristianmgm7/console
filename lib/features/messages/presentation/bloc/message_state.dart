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
    required this.users,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  });
  final List<MessageUiModel> messages;
  final Map<String, User> users;
  final bool isLoadingMore;
  final bool hasMoreMessages;

  @override
  List<Object?> get props => [messages, users, isLoadingMore, hasMoreMessages];

  MessageLoaded copyWith({
    List<MessageUiModel>? messages,
    Map<String, User>? users,
    bool? isLoadingMore,
    bool? hasMoreMessages,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      users: users ?? this.users,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
    );
  }
}

class MessageError extends MessageState {
  const MessageError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
