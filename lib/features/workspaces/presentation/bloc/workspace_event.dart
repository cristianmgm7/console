import 'package:equatable/equatable.dart';

sealed class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkspaces extends WorkspaceEvent {
  const LoadWorkspaces();
}

class SelectWorkspace extends WorkspaceEvent {
  const SelectWorkspace(this.workspaceId);
  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}
