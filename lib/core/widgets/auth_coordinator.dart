import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget that coordinates between AuthBloc and UserProfileCubit
/// Listens to auth state changes and triggers user profile actions accordingly
class AuthCoordinator extends StatefulWidget {
  const AuthCoordinator({required this.child, super.key});

  final Widget child;

  @override
  State<AuthCoordinator> createState() => _AuthCoordinatorState();
}

class _AuthCoordinatorState extends State<AuthCoordinator> {
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
      child: widget.child,
    );
  }
}
