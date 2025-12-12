import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
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
    required this.previewUiModel,
    required this.selectedMessageCount,
    required this.metadata,
  });

  final PreviewUiModel previewUiModel;
  final int selectedMessageCount;
  final PreviewMetadata metadata;

  bool get isValidSelection => selectedMessageCount >= 3 && selectedMessageCount <= 5;
  bool get isMetadataValid => metadata.title.trim().isNotEmpty && metadata.description.trim().isNotEmpty;
  bool get canPublish => isValidSelection && isMetadataValid;

  @override
  List<Object?> get props => [
    previewUiModel,
    selectedMessageCount,
    metadata,
  ];

  PreviewComposerLoaded copyWith({
    PreviewUiModel? previewUiModel,
    int? selectedMessageCount,
    PreviewMetadata? metadata,
  }) {
    return PreviewComposerLoaded(
      previewUiModel: previewUiModel ?? this.previewUiModel,
      selectedMessageCount: selectedMessageCount ?? this.selectedMessageCount,
      metadata: metadata ?? this.metadata,
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
