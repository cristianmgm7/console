import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/widgets/workspace_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarWorkspaceSection extends StatelessWidget {
  const SidebarWorkspaceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.zero,
      child: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, workspaceState) {
          return BlocBuilder<UserProfileCubit, UserProfileState>(
            builder: (context, userProfileState) {
              return switch (workspaceState) {
                WorkspaceInitial() => const SizedBox.shrink(),
                WorkspaceLoading() => const SizedBox(
                  height: 40,
                  child: Center(child: AppProgressIndicator()),
                ),
                WorkspaceLoaded() => _buildWorkspaceSelector(
                  workspaceState,
                  userProfileState,
                ),
                WorkspaceError() => const SizedBox.shrink(),
              };
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceSelector(
    WorkspaceLoaded loadedState,
    UserProfileState userProfileState,
  ) {
    final currentUserId = userProfileState is UserProfileLoaded
        ? userProfileState.user.id
        : loadedState.currentUserId ?? '';

    return WorkspaceSelector(
      currentUserId: currentUserId,
      workspaceState: loadedState,
    );
  }
}
