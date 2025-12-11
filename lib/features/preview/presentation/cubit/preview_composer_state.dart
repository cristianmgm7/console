import 'package:equatable/equatable.dart';

/// State for the preview composer form (UI-only demo version)
class PreviewComposerState extends Equatable {
  const PreviewComposerState({
    this.title = '',
    this.description = '',
    this.coverImageUrl,
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
    this.isPublishing = false,
    this.mockPreviewUrl,
  });

  final String title;
  final String description;
  final String? coverImageUrl;
  final String? titleError;
  final String? descriptionError;
  final String? coverImageUrlError;
  final bool isPublishing;
  final String? mockPreviewUrl;

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      coverImageUrlError == null;

  bool get hasErrors =>
      titleError != null || descriptionError != null || coverImageUrlError != null;

  PreviewComposerState copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
    bool? isPublishing,
    String? mockPreviewUrl,
  }) {
    return PreviewComposerState(
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      titleError: titleError,
      descriptionError: descriptionError,
      coverImageUrlError: coverImageUrlError,
      isPublishing: isPublishing ?? this.isPublishing,
      mockPreviewUrl: mockPreviewUrl ?? this.mockPreviewUrl,
    );
  }

  PreviewComposerState clearErrors() {
    return PreviewComposerState(
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      isPublishing: isPublishing,
      mockPreviewUrl: mockPreviewUrl,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        coverImageUrl,
        titleError,
        descriptionError,
        coverImageUrlError,
        isPublishing,
        mockPreviewUrl,
      ];
}
