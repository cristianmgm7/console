import 'package:carbon_voice_console/core/errors/failure_mapper.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/repositories/voice_memo_repository.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_event.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_state.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/mappers/voice_memo_ui_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class VoiceMemoBloc extends Bloc<VoiceMemoEvent, VoiceMemoState> {
  VoiceMemoBloc(
    this._voiceMemoRepository,
    this._logger,
  ) : super(const VoiceMemoInitial()) {
    on<LoadVoiceMemos>(_onLoadVoiceMemos);
  }

  final VoiceMemoRepository _voiceMemoRepository;
  final Logger _logger;

  Future<void> _onLoadVoiceMemos(
    LoadVoiceMemos event,
    Emitter<VoiceMemoState> emit,
  ) async {
    _logger.d(
      'Loading voice memos (workspace: ${event.workspaceId}, folder: ${event.folderId})',
    );

    emit(const VoiceMemoLoading());

    // Clear cache if force refresh
    if (event.forceRefresh) {
      _voiceMemoRepository.clearCache();
    }

    final result = await _voiceMemoRepository.getVoiceMemos(
      workspaceId: event.workspaceId,
      folderId: event.folderId,
    );

    result.fold(
      onSuccess: (voiceMemos) {
        _logger.d('Loaded ${voiceMemos.length} voice memos');

        // Filter out deleted and inactive voice memos
        final activeVoiceMemos = voiceMemos.where((voiceMemo) {
          // Filter out voice memos that have been deleted or are not active
          return voiceMemo.deletedAt == null && voiceMemo.status.toLowerCase() == 'active';
        }).toList();

        _logger.d('Filtered ${voiceMemos.length - activeVoiceMemos.length} deleted/inactive voice memos, keeping ${activeVoiceMemos.length} active voice memos');

        // Convert domain entities to UI models
        final uiModels = activeVoiceMemos.map((vm) => vm.toUiModel()).toList();

        emit(VoiceMemoLoaded(uiModels));
      },
      onFailure: (failure) {
        final errorMessage = FailureMapper.mapToMessage(failure.failure);
        _logger.e('Failed to load voice memos: $errorMessage');
        emit(VoiceMemoError(errorMessage));
      },
    );
  }
}
