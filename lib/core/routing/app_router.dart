import 'package:carbon_voice_console/core/providers/bloc_providers.dart';
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/routing/app_shell.dart';
import 'package:carbon_voice_console/core/routing/auth_guard.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/login_screen.dart';
import 'package:carbon_voice_console/features/auth/presentation/pages/oauth_callback_screen.dart';
import 'package:carbon_voice_console/features/settings/presentation/settings_screen.dart';
import 'package:carbon_voice_console/features/users/presentation/users_screen.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/voice_memos_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppRouter {
  AppRouter() {
    // Función para obtener la ruta inicial válida
    String getInitialLocation() {
      final basePath = Uri.base.path;
      debugPrint('📍 Uri.base.path: $basePath');

      // Para web, usar la URL actual (especialmente importante para OAuth callbacks)
      // Para desktop/mobile, usar login para evitar rutas del sistema de archivos
      if (kIsWeb) {
        // Detectar rutas del sistema de archivos y redirigir a login
        final isFileSystemPath = basePath.contains('/Users/') ||
            basePath.contains('/Library/') ||
            basePath.contains('/var/') ||
            basePath.contains('/private/') ||
            basePath.contains('/System/') ||
            basePath.contains('/Applications/') ||
            (!basePath.startsWith('/') && basePath.isNotEmpty) ||
            basePath.contains(r'\');

        if (isFileSystemPath) {
          debugPrint('📍 Detected file system path, using login');
          return AppRoutes.login;
        }

        // Si es una ruta válida o OAuth callback, usarla
        final validRoutes = [
          AppRoutes.login,
          AppRoutes.oauthCallback,
          AppRoutes.dashboard,
          AppRoutes.users,
          AppRoutes.voiceMemos,
          AppRoutes.settings,
        ];

        if (validRoutes.contains(basePath) || basePath.startsWith('/auth/callback')) {
          debugPrint('📍 Using current web path: $basePath');
          return basePath;
        }

        // Si no es válida, usar login
        debugPrint('📍 Invalid web path, using login');
        return AppRoutes.login;
      } else {
        // En desktop/mobile, siempre usar login
        debugPrint('📍 Desktop/mobile app, using login');
        return AppRoutes.login;
      }
    }

    final initialLoc = getInitialLocation();
    debugPrint('🚀 Initializing GoRouter with location: $initialLoc');
    
    router = GoRouter(
      initialLocation: initialLoc,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final path = state.uri.path;
        final authGuard = getAuthGuard();

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
          return AppRoutes.login;
        }

        // Check authentication for protected routes
        final authRedirect = await authGuard.getRedirect(context, path);
        if (authRedirect != null) {
          debugPrint('🔐 Authentication required, redirecting to: $authRedirect');
          return authRedirect;
        }

        // No redirigir si la ruta es válida y usuario está autenticado
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
  late final GoRouter router;
  GoRouter get instance => router;
}
