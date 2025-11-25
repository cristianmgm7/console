import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OAuthCallbackScreen extends StatefulWidget {
  final Uri callbackUri;

  const OAuthCallbackScreen({
    super.key,
    required this.callbackUri,
  });

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Enviar la URL completa al BLoC
    context.read<AuthBloc>().add(
      AuthorizationResponseReceived(widget.callbackUri.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text('Login successful! Redirecting...'),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
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
