import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserProfileButton extends StatelessWidget {
  const UserProfileButton({
    required this.isSelected,
    super.key,
  });

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AppContainer(
        backgroundColor: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoading) {
              return _buildLoadingState(context);
            }

            if (state is UserProfileLoaded) {
              return _buildLoadedState(context, state);
            }

            if (state is UserProfileError) {
              return _buildErrorState(context);
            }

            return _buildInitialState(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: AppProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, UserProfileLoaded state) {
    final user = state.user;
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return hasAvatar
        ? _buildAvatarButton(context, user)
        : _buildIconButton(context, user);
  }

  Widget _buildAvatarButton(BuildContext context, User user) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go(AppRoutes.settings),
      child: Tooltip(
        message: 'Settings - ${user.fullName}',
        child: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(user.avatarUrl!),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            AppIcons.user,
            size: 20,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, User user) {
    return AppIconButton(
      icon: AppIcons.user,
      onPressed: () => GoRouter.of(context).go(AppRoutes.settings),
      tooltip: 'Settings - ${user.fullName}',
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.user,
      onPressed: () => GoRouter.of(context).go(AppRoutes.settings),
      tooltip: 'Settings',
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.surface,
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.user,
      onPressed: () => GoRouter.of(context).go(AppRoutes.settings),
      tooltip: 'Settings',
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
    );
  }
}
