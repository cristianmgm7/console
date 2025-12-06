import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/widgets/workspace_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceSection extends StatelessWidget {
  const WorkspaceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, workspaceState) {
        return switch (workspaceState) {
          WorkspaceInitial() => _buildInitialState(),
          WorkspaceLoading() => _buildLoadingState(),
          WorkspaceLoaded() => _buildLoadedState(workspaceState),
          WorkspaceError() => _buildErrorState(workspaceState),
        };
      },
    );
  }

  Widget _buildInitialState() {
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      width: 200,
      height: 40,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: AppProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildLoadedState(WorkspaceLoaded loadedState) {
    // Get current user ID from auth or user profile
    // TODO: Replace with actual current user ID from auth
    final currentUserId = loadedState.currentUserId ?? '';

    return WorkspaceSelector(
      currentUserId: currentUserId,
      workspaceState: loadedState,
    );
  }

  Widget _buildErrorState(WorkspaceError errorState) {
    return const SizedBox.shrink(); // Or show error indicator if needed
  }
}
