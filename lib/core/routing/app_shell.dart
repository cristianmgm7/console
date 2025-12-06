import 'package:carbon_voice_console/core/routing/side_navigation_bar.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) async {
        final userProfileCubit = context.read<UserProfileCubit>();

        switch (authState) {
          case Authenticated():
            // Load user profile when user becomes authenticated
            await userProfileCubit.loadCurrentUser();

          case Unauthenticated() || AuthError() || LoggedOut():
            // Clear user profile when user logs out or auth fails
            userProfileCubit.clearProfile();

          default:
            // No action needed for other states
            break;
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // Fixed-width left navigation bar
            const SideNavigationBar(),
            // Main content area
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
