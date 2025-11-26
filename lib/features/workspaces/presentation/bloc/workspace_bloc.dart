import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc(
    this._workspaceRepository,
    this._logger,
  ) : super(const WorkspaceInitial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<SelectWorkspace>(_onSelectWorkspace);
  }

  final WorkspaceRepository _workspaceRepository;
  final Logger _logger;

  Future<void> _onLoadWorkspaces(
    LoadWorkspaces event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());

    final result = await _workspaceRepository.getWorkspaces();

    result.fold(
      onSuccess: (workspaces) {
        if (workspaces.isEmpty) {
          emit(const WorkspaceError('No workspaces found'));
          return;
        }
        final selected = workspaces.first;
        _logger.i('Auto-selected workspace: ${selected.name}');
        emit(WorkspaceLoaded(workspaces, selected));
        // State change will trigger dashboard screen to notify ConversationBloc
      },
      onFailure: (failure) {
        emit(WorkspaceError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onSelectWorkspace(
    SelectWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkspaceLoaded) return;

    final selected = currentState.workspaces.firstWhere(
      (w) => w.id == event.workspaceId,
      orElse: () => currentState.selectedWorkspace!,
    );

    emit(WorkspaceLoaded(currentState.workspaces, selected));
    // State change will trigger dashboard screen to notify ConversationBloc
  }
}
