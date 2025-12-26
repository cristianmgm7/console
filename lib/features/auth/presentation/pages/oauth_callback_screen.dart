import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/web/web_stub.dart'
    if (dart.library.html) 'package:web/web.dart' as web;
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({
    required this.callbackUri, super.key,
  });

  final Uri callbackUri;

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
      final currentUrl = web.window.location.href;
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        // Navigate to dashboard when authenticated
        if (state is Authenticated) {
          // Use a small delay to ensure the state is fully processed
          await Future.microtask(( ) {
            if (context.mounted) {
              context.go(AppRoutes.dashboard);
            }
          });
        } else if (state is AuthError) {
          // Show error snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        // Log from the state

        if (state is AuthError) {
        } else if (state is Authenticated) {
        } else if (state is ProcessingCallback) {}

        if (state is ProcessingCallback) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientPurple,
                  AppColors.gradientPink,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.gradientPurple.withValues(alpha: 0.3),
                    AppColors.gradientPink.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: const Center(
                child: AppProgressIndicator(),
              ),
            ),
          );
        }
        if (state is Authenticated) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientPurple,
                  AppColors.gradientPink,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.gradientPurple.withValues(alpha: 0.3),
                    AppColors.gradientPink.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Text(
                  'Login successful! Redirecting...',
                  style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          );
        }
        if (state is AuthError) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientPurple,
                  AppColors.gradientPink,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.gradientPurple.withValues(alpha: 0.3),
                    AppColors.gradientPink.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: AppTextStyle.bodyLarge.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      onPressed: () {
                        context.go(AppRoutes.login);
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientPurple,
                AppColors.gradientPink,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  AppColors.gradientPurple.withValues(alpha: 0.3),
                  AppColors.gradientPink.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Text(
                'Processing login...',
                style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        );
      },
    );
  }
}
