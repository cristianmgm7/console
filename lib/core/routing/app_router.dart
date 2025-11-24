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
    router = GoRouter(
      initialLocation: AppRoutes.login,
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
            final code = state.uri.queryParameters['code'];
            final stateParam = state.uri.queryParameters['state'];
            final error = state.uri.queryParameters['error'];

            return MaterialPage(
              key: state.pageKey,
              child: OAuthCallbackScreen(
                code: code,
                state: stateParam,
                error: error,
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
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.path}'),
        ),
      ),
    );
  }

  GoRouter get instance => router;
}



