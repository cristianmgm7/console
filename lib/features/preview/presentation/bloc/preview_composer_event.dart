import 'package:equatable/equatable.dart';

sealed class PreviewComposerEvent extends Equatable {
  const PreviewComposerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the preview composer and fetch data
class PreviewComposerStarted extends PreviewComposerEvent {
  const PreviewComposerStarted({
    required this.conversationId,
    required this.messageIds,
  });

  final String conversationId;
  final List<String> messageIds;

  @override
  List<Object?> get props => [conversationId, messageIds];
}


/// Event to publish the preview
class PreviewPublishRequested extends PreviewComposerEvent {
  const PreviewPublishRequested();
}

/// Event to reset the composer state
class PreviewComposerReset extends PreviewComposerEvent {
  const PreviewComposerReset();
}
