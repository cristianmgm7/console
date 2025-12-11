import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
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

/// Data loaded successfully, ready for user input
class PreviewComposerLoaded extends PreviewComposerState {
  const PreviewComposerLoaded({
    required this.composerData,
    required this.currentMetadata,
    required this.previewUiModel, // NEW
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
  });

  final PreviewComposerData composerData;
  final PreviewMetadata currentMetadata;
  final PreviewUiModel previewUiModel; // NEW - UI model for visualization
  final String? titleError;
  final String? descriptionError;
  final String? coverImageUrlError;

  bool get isValid =>
      currentMetadata.title.trim().isNotEmpty &&
      currentMetadata.description.trim().isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      coverImageUrlError == null;

  @override
  List<Object?> get props => [
    composerData,
    currentMetadata,
    previewUiModel, // NEW
    titleError,
    descriptionError,
    coverImageUrlError,
  ];

  PreviewComposerLoaded copyWith({
    PreviewComposerData? composerData,
    PreviewMetadata? currentMetadata,
    PreviewUiModel? previewUiModel, // NEW
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
  }) {
    return PreviewComposerLoaded(
      composerData: composerData ?? this.composerData,
      currentMetadata: currentMetadata ?? this.currentMetadata,
      previewUiModel: previewUiModel ?? this.previewUiModel, // NEW
      titleError: titleError,
      descriptionError: descriptionError,
      coverImageUrlError: coverImageUrlError,
    );
  }
}

/// Publishing preview in progress
class PreviewComposerPublishing extends PreviewComposerState {
  const PreviewComposerPublishing({
    required this.composerData,
    required this.metadata,
  });

  final PreviewComposerData composerData;
  final PreviewMetadata metadata;

  @override
  List<Object?> get props => [composerData, metadata];
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
