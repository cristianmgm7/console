import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/routing/app_shell.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/login_screen.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/oauth_callback_screen.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/dashboard_screen.dart';
import 'package:carbon_voice_console/features/settings/presentation/settings_screen.dart';
import 'package:carbon_voice_console/features/users/presentation/users_screen.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/voice_memos_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppRouter {
  AppRouter() {
    // Función para obtener la ruta inicial válida
    // En macOS/iOS, siempre usar /login como ruta inicial
    // porque Uri.base.path puede contener rutas del sistema de archivos
    String getInitialLocation() {
      final basePath = Uri.base.path;
      debugPrint('📍 Uri.base.path: $basePath');
      
      // En desktop/mobile, siempre empezar en login
      // Solo en web usamos Uri.base.path
      debugPrint('📍 Using initial location: ${AppRoutes.login}');
      return AppRoutes.login;
    }

    final initialLoc = getInitialLocation();
    debugPrint('🚀 Initializing GoRouter with location: $initialLoc');
    
    router = GoRouter(
      initialLocation: initialLoc,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final path = state.uri.path;
        debugPrint('🔀 GoRouter redirect check: $path');
        
        // Detectar rutas del sistema de archivos y redirigir a login
        final isFileSystemPath = path.contains('/Users/') ||
            path.contains('/Library/') ||
            path.contains('/var/') ||
            path.contains('/private/') ||
            path.contains('/System/') ||
            path.contains('/Applications/') ||
            (!path.startsWith('/') && path.isNotEmpty) ||
            path.contains(r'\');
        
        if (isFileSystemPath) {
          debugPrint('🔀 Redirecting from file system path to /login');
          return AppRoutes.login;
        }
        
        // Si la ruta está vacía o es solo "/", redirigir a login
        if (path.isEmpty || path == '/') {
          debugPrint('🔀 Redirecting empty path to /login');
          return AppRoutes.login;
        }
        
        // Validar que la ruta sea válida
        final validRoutes = [
          AppRoutes.login,
          AppRoutes.oauthCallback,
          AppRoutes.dashboard,
          AppRoutes.users,
          AppRoutes.voiceMemos,
          AppRoutes.settings,
        ];
        
        // Si no es una ruta válida y no es un callback, redirigir a login
        if (!validRoutes.contains(path) && !path.startsWith('/auth/callback')) {
          debugPrint('🔀 Redirecting invalid path "$path" to /login');
          return AppRoutes.login;
        }
        
        // No redirigir si la ruta es válida
        debugPrint('✅ GoRouter allowing path: $path');
        return null;
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
        // Log del error para debugging
        debugPrint('🚨 GoRouter Error: ${state.uri.path}');
        debugPrint('🚨 GoRouter Error - Full URI: ${state.uri}');
        debugPrint('🚨 GoRouter Error - Matched subloc: ${state.matchedLocation}');
        
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
  late final GoRouter router;
  GoRouter get instance => router;
}
