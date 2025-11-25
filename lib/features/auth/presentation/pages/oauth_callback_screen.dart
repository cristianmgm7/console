import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:html' as html;
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
    // Log para debugging en consola del navegador

    // En web, usar la URL completa del navegador para obtener los query params
    String fullUrl;
    if (kIsWeb) {
      final currentUrl = html.window.location.href;
      fullUrl = currentUrl;
    } else {
      // En otras plataformas, usar la URI del router
      fullUrl = widget.callbackUri.toString();
    }

    // Enviar la URL completa al BLoC
    context.read<AuthBloc>().add(
          AuthorizationResponseReceived(fullUrl),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Log del estado actual para debugging

        if (state is AuthError) {
        } else if (state is Authenticated) {
        } else if (state is ProcessingCallback) {}

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
