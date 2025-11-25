import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/oauth_callback_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/voice_memos/presentation/voice_memos_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_routes.dart';

@singleton
class AppRouter {
  late final GoRouter router;
  AppRouter() {
    // Usar la URL actual como initialLocation, o /login si no hay path
    final initialPath = Uri.base.path.isEmpty || Uri.base.path == '/'
        ? AppRoutes.login
        : Uri.base.path;
    router = GoRouter(
      initialLocation: initialPath,
      debugLogDiagnostics: true,
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
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
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
        return Scaffold(
          body: Center(
            child: Text('Page not found: ${state.uri.path}'),
          ),
        );
      },
    );

    // Log cuando el router está listo
  }
  GoRouter get instance => router;
}
