import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/users/presentation/users_page.dart';
import '../../features/voice_memos/presentation/voice_memos_page.dart';
import '../../features/settings/presentation/settings_page.dart';
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
            child: const LoginPage(),
          ),
        ),
        // Authenticated routes wrapped in AppShell
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.users,
              name: 'users',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UsersPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.voiceMemos,
              name: 'voiceMemos',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: VoiceMemosPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
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



