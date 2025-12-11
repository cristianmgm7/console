import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerCubit extends Cubit<PreviewComposerState> {
  PreviewComposerCubit(this._logger) : super(const PreviewComposerState());

  final Logger _logger;

  static const int maxDescriptionLength = 200;

  /// Initialize form with conversation data
  void initialize({
    required String conversationTitle,
    String? conversationDescription,
    String? conversationImageUrl,
  }) {
    _logger.d('Initializing preview composer');
    emit(PreviewComposerState(
      title: conversationTitle,
      description: conversationDescription ?? '',
      coverImageUrl: conversationImageUrl,
    ));
  }

  /// Update title field
  void updateTitle(String title) {
    String? error;

    if (title.trim().isEmpty) {
      error = 'Title is required';
    } else if (title.trim().length > 100) {
      error = 'Title must be 100 characters or less';
    }

    emit(state.copyWith(
      title: title,
      titleError: error,
    ));
  }

  /// Update description field
  void updateDescription(String description) {
    String? error;

    if (description.trim().isEmpty) {
      error = 'Description is required';
    } else if (description.trim().length > maxDescriptionLength) {
      error = 'Description must be $maxDescriptionLength characters or less';
    }

    emit(state.copyWith(
      description: description,
      descriptionError: error,
    ));
  }

  /// Update cover image URL field
  void updateCoverImageUrl(String? url) {
    String? error;

    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Invalid URL format';
      }
    }

    emit(state.copyWith(
      coverImageUrl: url?.trim(),
      coverImageUrlError: error,
    ));
  }

  /// Validate all fields
  bool validate() {
    String? titleError;
    String? descriptionError;

    if (state.title.trim().isEmpty) {
      titleError = 'Title is required';
    } else if (state.title.trim().length > 100) {
      titleError = 'Title must be 100 characters or less';
    }

    if (state.description.trim().isEmpty) {
      descriptionError = 'Description is required';
    } else if (state.description.trim().length > maxDescriptionLength) {
      descriptionError =
          'Description must be $maxDescriptionLength characters or less';
    }

    if (titleError != null || descriptionError != null) {
      emit(state.copyWith(
        titleError: titleError,
        descriptionError: descriptionError,
      ));
      return false;
    }

    return true;
  }

  /// Mock publish operation (simulates API call)
  Future<void> mockPublish({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    _logger.i('Mock publishing preview for conversation: $conversationId');
    _logger.d('Selected message IDs: ${messageIds.join(", ")}');

    // Set publishing state
    emit(state.copyWith(isPublishing: true));

    // Simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));

    // Generate mock preview URL
    final mockUrl = 'https://carbonvoice.app/preview/demo_${DateTime.now().millisecondsSinceEpoch}';

    _logger.i('Mock preview published: $mockUrl');

    // Update state with mock URL
    emit(state.copyWith(
      isPublishing: false,
      mockPreviewUrl: mockUrl,
    ));
  }

  /// Reset form state
  void reset() {
    _logger.d('Resetting preview composer');
    emit(const PreviewComposerState());
  }
}
