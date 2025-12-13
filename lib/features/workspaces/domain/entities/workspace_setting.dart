import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for a workspace setting with typed reason
class WorkspaceSetting extends Equatable {
  const WorkspaceSetting({
    required this.value,
    required this.reason,
  });

  final bool value;
  final WorkspaceSettingReason reason;

  @override
  List<Object?> get props => [value, reason];
}
