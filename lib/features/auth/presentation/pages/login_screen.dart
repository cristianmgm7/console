import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is RedirectToOAuth) {
          final uri = Uri.parse(state.url);
          if (await canLaunchUrl(uri)) {
            // En web, redirigir en la misma ventana para que el callback funcione
            // En desktop/mobile, abrir en aplicación externa
            if (kIsWeb) {

              await launchUrl(uri, webOnlyWindowName: '_self');
            } else {

              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch login URL')),
              );
            }
          }
        } else if (state is Authenticated) {
          // Navigate to dashboard when authentication succeeds
          // This handles desktop flow where loginWithDesktop completes successfully
          if (context.mounted) {
            context.go(AppRoutes.dashboard);
          }
        } else if (state is AuthError) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Carbon Voice Downloader',
                    style: AppTextStyle.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
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
      ),
    );
  }
}
