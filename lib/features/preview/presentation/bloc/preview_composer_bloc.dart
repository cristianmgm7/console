import 'package:carbon_voice_console/features/preview/domain/usecases/get_preview_composer_data_usecase.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/publish_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerBloc
    extends Bloc<PreviewComposerEvent, PreviewComposerState> {
  PreviewComposerBloc(
    this._getPreviewComposerDataUsecase,
    this._publishPreviewUsecase,
    this._logger,
  ) : super(const PreviewComposerInitial()) {
    on<PreviewComposerStarted>(_onStarted);
    on<PreviewTitleUpdated>(_onTitleUpdated);
    on<PreviewDescriptionUpdated>(_onDescriptionUpdated);
    on<PreviewCoverImageUpdated>(_onCoverImageUpdated);
    on<PreviewPublishRequested>(_onPublishRequested);
    on<PreviewComposerReset>(_onReset);
  }

  final GetPreviewComposerDataUsecase _getPreviewComposerDataUsecase;
  final PublishPreviewUsecase _publishPreviewUsecase;
  final Logger _logger;

  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 200;

  Future<void> _onStarted(
    PreviewComposerStarted event,
    Emitter<PreviewComposerState> emit,
  ) async {
    emit(const PreviewComposerLoading());

    final result = await _getPreviewComposerDataUsecase(
      conversationId: event.conversationId,
      messageIds: event.messageIds,
    );

    result.fold(
      onSuccess: (composerData) {
        _logger.i('Preview composer data loaded successfully');
        emit(PreviewComposerLoaded(
          composerData: composerData,
          currentMetadata: composerData.initialMetadata,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to load preview composer data: ${failure.failure.code}');
        emit(PreviewComposerError(
          failure.failure.details ?? 'Failed to load preview data',
        ));
      },
    );
  }

  void _onTitleUpdated(
    PreviewTitleUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.title.trim().isEmpty) {
      error = 'Title is required';
    } else if (event.title.trim().length > maxTitleLength) {
      error = 'Title must be $maxTitleLength characters or less';
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      title: event.title,
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      titleError: error,
    ));
  }

  void _onDescriptionUpdated(
    PreviewDescriptionUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.description.trim().isEmpty) {
      error = 'Description is required';
    } else if (event.description.trim().length > maxDescriptionLength) {
      error = 'Description must be $maxDescriptionLength characters or less';
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      description: event.description,
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      descriptionError: error,
    ));
  }

  void _onCoverImageUpdated(
    PreviewCoverImageUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.coverImageUrl != null && event.coverImageUrl!.trim().isNotEmpty) {
      final uri = Uri.tryParse(event.coverImageUrl!);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Invalid URL format';
      }
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      coverImageUrl: event.coverImageUrl?.trim(),
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      coverImageUrlError: error,
    ));
  }

  Future<void> _onPublishRequested(
    PreviewPublishRequested event,
    Emitter<PreviewComposerState> emit,
  ) async {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;

    // Final validation
    if (!loadedState.isValid) {
      _logger.w('Publish requested but form is invalid');
      return;
    }

    emit(PreviewComposerPublishing(
      composerData: loadedState.composerData,
      metadata: loadedState.currentMetadata,
    ));

    final messageIds = loadedState.composerData.selectedMessages
        .map((msg) => msg.id)
        .toList();

    final result = await _publishPreviewUsecase(
      conversationId: loadedState.composerData.conversation.id,
      metadata: loadedState.currentMetadata,
      messageIds: messageIds,
    );

    result.fold(
      onSuccess: (previewUrl) {
        _logger.i('Preview published successfully: $previewUrl');
        emit(PreviewComposerPublishSuccess(previewUrl: previewUrl));
      },
      onFailure: (failure) {
        _logger.e('Failed to publish preview: ${failure.failure.code}');
        // Return to loaded state with error message
        emit(PreviewComposerError(
          failure.failure.details ?? 'Failed to publish preview',
        ));
      },
    );
  }

  void _onReset(
    PreviewComposerReset event,
    Emitter<PreviewComposerState> emit,
  ) {
    emit(const PreviewComposerInitial());
  }
}
