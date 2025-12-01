import 'package:carbon_voice_console/core/providers/bloc_providers.dart';
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/routing/app_shell.dart';
import 'package:carbon_voice_console/core/routing/route_guard.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/login_screen.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/oauth_callback_screen.dart';
import 'package:carbon_voice_console/features/settings/presentation/settings_screen.dart';
import 'package:carbon_voice_console/features/users/presentation/users_screen.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/voice_memos_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(this.routeGuard) {
    _initializeRouter();
  }

  final RouteGuard routeGuard;

  late final GoRouter router;

  void _initializeRouter() {
    final initialLoc = routeGuard.getInitialLocation();
    debugPrint('🚀 Initializing GoRouter with location: $initialLoc');

    router = GoRouter(
      initialLocation: initialLoc,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final path = state.uri.path;
        return routeGuard.getRedirect(context, path);
      },
      routes: [
        // Standalone login route (no shell)
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),
        // OAuth callback route (no shell)
        GoRoute(
          path: AppRoutes.oauthCallback,
          name: 'oauthCallback',
          pageBuilder: (context, state) {
            // Log para debugging

            // Usar la URI completa con todos los query parameters
            final fullUri = state.uri;

            return MaterialPage(
              key: state.pageKey,
              child: OAuthCallbackScreen(
                callbackUri: fullUri,
              ),
            );
          },
        ),
        // Authenticated routes wrapped in AppShell
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProviders.blocProvidersDashboard(),
              ),
            ),
            GoRoute(
              path: AppRoutes.users,
              name: 'users',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UsersScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.voiceMemos,
              name: 'voiceMemos',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: VoiceMemosScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) {
        
        // Redirigir a login inmediatamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        });
        
        // Mientras tanto, mostrar loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  GoRouter get instance => router;
}
