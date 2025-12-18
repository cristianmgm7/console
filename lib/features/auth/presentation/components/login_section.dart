import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginSection extends StatelessWidget {
  const LoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      size: AppButtonSize.medium,
      onPressed: () {
        context.read<AuthBloc>().add(const LoginRequested());
      },
      child: const Text('Login with Carbon Voice'),
    );
  }
}
