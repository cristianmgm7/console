import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
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
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, userProfileState) {
            return switch (workspaceState) {
              WorkspaceInitial() => _buildInitialState(),
              WorkspaceLoading() => _buildLoadingState(),
              WorkspaceLoaded() => _buildLoadedState(workspaceState, userProfileState),
              WorkspaceError() => _buildErrorState(workspaceState),
            };
          },
        );
      },
    );
  }
  

  Widget _buildInitialState() {
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Workspace',
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
          const SizedBox(
          width: 200,
          height: 40,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: AppProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(WorkspaceLoaded loadedState, UserProfileState userProfileState) {
    // Get current user ID from user profile cubit
    final currentUserId = userProfileState is UserProfileLoaded
        ? userProfileState.user.id
        : loadedState.currentUserId ?? '';

    return WorkspaceSelector(
      currentUserId: currentUserId,
      workspaceState: loadedState,
    );
  }

  Widget _buildErrorState(WorkspaceError errorState) {
    return const SizedBox.shrink(); // Or show error indicator if needed
  }
}
