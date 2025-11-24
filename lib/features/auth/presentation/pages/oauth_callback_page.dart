import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OAuthCallbackPage extends StatefulWidget {
  final String? code;
  final String? state;
  final String? error;

  const OAuthCallbackPage({
    super.key,
    this.code,
    this.state,
    this.error,
  });

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    if (widget.code != null && widget.state != null) {
      context.read<AuthBloc>().add(OAuthCallbackReceived(
            code: widget.code!,
            state: widget.state!,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return Scaffold(
        body: Center(
          child: Text('Login failed: ${widget.error}'),
        ),
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is ProcessingCallback) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is Authenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Login successful! You can close this window.'),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${state.message}'),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text('Processing login...'),
          ),
        );
      },
    );
  }
}
