import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/user_profile_avatar.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/user_profile_info.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileSection extends StatelessWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoading) {
              return _buildLoadingState();
            }

            if (state is UserProfileLoaded) {
              return _buildLoadedState(state);
            }

            if (state is UserProfileError) {
              return _buildErrorState();
            }

            // Initial state - return loading and trigger load in post-frame callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<UserProfileCubit>().loadCurrentUser();
              }
            });
            return _buildInitialState();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: AppProgressIndicator(),
    );
  }

  Widget _buildLoadedState(UserProfileLoaded state) {
    return Column(
      children: [
        UserProfileAvatar(user: state.user),
        const SizedBox(height: 16),
        UserProfileInfo(user: state.user),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text('Failed to load user profile'),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: AppProgressIndicator(),
    );
  }
}
