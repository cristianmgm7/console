import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/get_preview_composer_data_usecase.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/publish_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerBloc extends Bloc<PreviewComposerEvent, PreviewComposerState> {
  PreviewComposerBloc(
    this._getPreviewComposerDataUsecase,
    this._publishPreviewUsecase,
    this._logger,
  ) : super(const PreviewComposerInitial()) {
    on<PreviewComposerStarted>(_onStarted);
    on<PreviewPublishRequested>(_onPublishRequested);
    on<PreviewComposerReset>(_onReset);
  }

  final GetPreviewComposerDataUsecase _getPreviewComposerDataUsecase;
  final PublishPreviewUsecase _publishPreviewUsecase;
  final Logger _logger;

  // Store data needed for publishing
  late String? _conversationId;
  late List<String>? _selectedMessageIds;

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
      onSuccess: (enrichedData) {
        _logger.i('Preview composer data loaded successfully');

        // Store data needed for publishing
        _conversationId = enrichedData.composerData.conversation.channelGuid;
        _selectedMessageIds = enrichedData.composerData.selectedMessages.map((msg) => msg.id).toList();

        // Transform to UI model using mapper
        final previewUiModel = enrichedData.composerData.toPreviewUiModel(enrichedData.userMap);

        emit(
          PreviewComposerLoaded(
            previewUiModel: previewUiModel,
            selectedMessageCount: enrichedData.composerData.selectedMessages.length,
            metadata: enrichedData.composerData.initialMetadata,
          ),
        );
      },
      onFailure: (failure) {
        _logger.e('Failed to load preview composer data: ${failure.failure.code}');
        emit(
          PreviewComposerError(
            failure.failure.details ?? 'Failed to load preview data',
          ),
        );
      },
    );
  }




  Future<void> _onPublishRequested(
    PreviewPublishRequested event,
    Emitter<PreviewComposerState> emit,
  ) async {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;

    // Basic validation - metadata is already validated in the state
    if (!loadedState.canPublish) {
      _logger.w('Publish requested but validation failed');
      return;
    }

    emit(const PreviewComposerPublishing());

    final result = await _publishPreviewUsecase(
      conversationId: _conversationId!,
      metadata: loadedState.metadata,
      messageIds: _selectedMessageIds!,
    );

    result.fold(
      onSuccess: (previewUrl) {
        _logger.i('Preview published successfully: $previewUrl');
        emit(PreviewComposerPublishSuccess(previewUrl: previewUrl));
      },
      onFailure: (failure) {
        _logger.e('Failed to publish preview: ${failure.failure.code}');
        // Return to loaded state with error message
        emit(
          PreviewComposerError(
            failure.failure.details ?? 'Failed to publish preview',
          ),
        );
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
