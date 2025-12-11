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

/// Event to update the title field
class PreviewTitleUpdated extends PreviewComposerEvent {
  const PreviewTitleUpdated(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

/// Event to update the description field
class PreviewDescriptionUpdated extends PreviewComposerEvent {
  const PreviewDescriptionUpdated(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

/// Event to update the cover image URL field
class PreviewCoverImageUpdated extends PreviewComposerEvent {
  const PreviewCoverImageUpdated(this.coverImageUrl);

  final String? coverImageUrl;

  @override
  List<Object?> get props => [coverImageUrl];
}

/// Event to publish the preview
class PreviewPublishRequested extends PreviewComposerEvent {
  const PreviewPublishRequested();
}

/// Event to reset the composer state
class PreviewComposerReset extends PreviewComposerEvent {
  const PreviewComposerReset();
}
