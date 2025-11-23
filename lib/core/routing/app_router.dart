import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/users/view/users_page.dart';
import 'app_routes.dart';

@singleton
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const DashboardPage(),
          ),
          routes: [
            GoRoute(
              path: 'users',
              name: 'users',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const UsersPage(),
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

