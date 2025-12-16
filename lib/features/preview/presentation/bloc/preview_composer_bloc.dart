import 'package:carbon_voice_console/features/conversations/presentation/mappers/conversation_ui_mapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart';
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
        _conversationId = enrichedData.conversation.channelGuid;
        _selectedMessageIds = enrichedData.selectedMessages.map((msg) => msg.id).toList();

        // Convert conversation to UI model
        final conversationUiModel = enrichedData.conversation.toUiModel();

        // Sort messages by creation date (oldest first) and convert to UI models
        final sortedSelectedMessages = enrichedData.selectedMessages
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sort oldest first

        final selectedMessageUiModels = sortedSelectedMessages
            .map((message) => message.toUiModel()) // Uses existing MessageUiMapper
            .toList();

        final parentMessageUiModels = enrichedData.parentMessages
            .map((message) => message.toUiModel()) // Uses existing MessageUiMapper
            .toList();

        emit(
          PreviewComposerLoaded(
            conversation: conversationUiModel,
            selectedMessages: selectedMessageUiModels,
            parentMessages: parentMessageUiModels,
            selectedMessageCount: enrichedData.selectedMessages.length,
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

    // Basic validation
    if (!loadedState.isValidSelection) {
      _logger.w('Publish requested but validation failed');
      return;
    }

    emit(const PreviewComposerPublishing());

    final result = await _publishPreviewUsecase(
      conversationId: _conversationId!,
      messageIds: _selectedMessageIds!,
      title: loadedState.conversation.name,
      description: loadedState.conversation.description,
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
