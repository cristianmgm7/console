import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc(
    this._workspaceRepository,
    ) : super(const WorkspaceInitial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<SelectWorkspace>(_onSelectWorkspace);
  }

  final WorkspaceRepository _workspaceRepository;

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

        // Filter out hidden workspaces if userId provided
        final visibleWorkspaces = event.currentUserId != null
            ? workspaces.where((w) => !w.shouldBeHidden).toList()
            : workspaces;

        if (visibleWorkspaces.isEmpty) {
          emit(const WorkspaceError('No accessible workspaces found'));
          return;
        }

        final selected = visibleWorkspaces.first;
        emit(WorkspaceLoaded(
          visibleWorkspaces,
          selected,
          currentUserId: event.currentUserId,
        ));
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

    emit(WorkspaceLoaded(
      currentState.workspaces,
      selected,
      currentUserId: currentState.currentUserId,
    ));
    // State change will trigger dashboard screen to notify ConversationBloc
  }
}
