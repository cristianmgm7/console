import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:equatable/equatable.dart';

sealed class WorkspaceState extends Equatable {
  const WorkspaceState();

  @override
  List<Object?> get props => [];
}

class WorkspaceInitial extends WorkspaceState {
  const WorkspaceInitial();
}

class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

class WorkspaceLoaded extends WorkspaceState {
  const WorkspaceLoaded(
    this.workspaces,
    this.selectedWorkspace, {
    this.currentUserId,
  });
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final String? currentUserId;

  @override
  List<Object?> get props => [workspaces, selectedWorkspace, currentUserId];
}

class WorkspaceError extends WorkspaceState {
  const WorkspaceError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
