import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is RedirectToOAuth) {
          final uri = Uri.parse(state.url);
          print('🟡 LoginScreen: Redirecting to OAuth URL: ${state.url}');
          
          if (await canLaunchUrl(uri)) {
            // En web, redirigir en la misma ventana para que el callback funcione
            // En desktop/mobile, abrir en aplicación externa
            if (kIsWeb) {
              print('🟡 LoginScreen: Web detected - redirecting in same window');
              await launchUrl(uri, webOnlyWindowName: '_self');
            } else {
              print('🟡 LoginScreen: Non-web platform - opening external application');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            print('🔴 LoginScreen: Could not launch URL');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch login URL')),
              );
            }
          }
        } else if (state is AuthError) {
          print('🔴 LoginScreen: AuthError - ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Carbon Voice',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const LoginRequested());
                  },
                  child: const Text('Login with OAuth'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
