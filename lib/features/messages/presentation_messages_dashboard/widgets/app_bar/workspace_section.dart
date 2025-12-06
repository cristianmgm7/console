import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/widgets/workspace_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceSection extends StatelessWidget {
  const WorkspaceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceBloc, WorkspaceState, WorkspaceLoaded?>(
      selector: (state) => state is WorkspaceLoaded ? state : null,
      builder: (context, workspaceState) {
        if (workspaceState == null || workspaceState.workspaces.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get current user ID from auth or user profile
        // TODO: Replace with actual current user ID from auth
        final currentUserId = workspaceState.currentUserId ?? '';

        return WorkspaceSelector(
          currentUserId: currentUserId,
        );
      },
    );
  }
}
