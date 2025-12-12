import 'package:equatable/equatable.dart';

/// Metadata for a conversation preview (user-editable fields)
class PreviewMetadata extends Equatable {
  const PreviewMetadata({
    required this.title,
    required this.description,
    this.coverImageUrl,
  });

  final String title;
  final String description;
  final String? coverImageUrl;

  @override
  List<Object?> get props => [title, description, coverImageUrl];

  PreviewMetadata copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
  }) {
    return PreviewMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
