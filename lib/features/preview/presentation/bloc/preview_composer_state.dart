import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:equatable/equatable.dart';

sealed class PreviewComposerState extends Equatable {
  const PreviewComposerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class PreviewComposerInitial extends PreviewComposerState {
  const PreviewComposerInitial();
}

/// Loading conversation and message data
class PreviewComposerLoading extends PreviewComposerState {
  const PreviewComposerLoading();
}

/// Data loaded successfully, ready for publishing
class PreviewComposerLoaded extends PreviewComposerState {
  const PreviewComposerLoaded({
    required this.conversation,
    required this.selectedMessages,
    required this.parentMessages,
    required this.selectedMessageCount,
  });

  final ConversationUiModel conversation;
  final List<MessageUiModel> selectedMessages;
  final List<MessageUiModel> parentMessages;
  final int selectedMessageCount;

  bool get isValidSelection => selectedMessageCount >= 3 && selectedMessageCount <= 10;

  @override
  List<Object?> get props => [
    conversation,
    selectedMessages,
    parentMessages,
    selectedMessageCount,
  ];

  PreviewComposerLoaded copyWith({
    ConversationUiModel? conversation,
    List<MessageUiModel>? selectedMessages,
    List<MessageUiModel>? parentMessages,
    int? selectedMessageCount,
  }) {
    return PreviewComposerLoaded(
      conversation: conversation ?? this.conversation,
      selectedMessages: selectedMessages ?? this.selectedMessages,
      parentMessages: parentMessages ?? this.parentMessages,
      selectedMessageCount: selectedMessageCount ?? this.selectedMessageCount,
    );
  }
}

/// Publishing preview in progress
class PreviewComposerPublishing extends PreviewComposerState {
  const PreviewComposerPublishing();

  @override
  List<Object?> get props => [];
}

/// Preview published successfully
class PreviewComposerPublishSuccess extends PreviewComposerState {
  const PreviewComposerPublishSuccess({
    required this.previewUrl,
  });

  final String previewUrl;

  @override
  List<Object?> get props => [previewUrl];
}

/// Error loading data or publishing
class PreviewComposerError extends PreviewComposerState {
  const PreviewComposerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
