import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Service to guard and validate all routes, including authentication and path validation
@LazySingleton()
class RouteGuard {
  RouteGuard(this._oauthRepository);

  final OAuthRepository _oauthRepository;

  /// Routes that don't require authentication
  static const List<String> publicRoutes = [
    AppRoutes.login,
    AppRoutes.oauthCallback,
  ];

  /// All valid routes in the application
  static const List<String> validRoutes = [
    AppRoutes.login,
    AppRoutes.oauthCallback,
    AppRoutes.dashboard,
    AppRoutes.users,
    AppRoutes.voiceMemos,
    AppRoutes.settings,
  ];

  /// Check if a path looks like a file system path that should be redirected
  bool _isFileSystemPath(String path) {
    return path.contains('/Users/') ||
        path.contains('/Library/') ||
        path.contains('/var/') ||
        path.contains('/private/') ||
        path.contains('/System/') ||
        path.contains('/Applications/') ||
        (!path.startsWith('/') && path.isNotEmpty) ||
        path.contains(r'\');
  }

  /// Check if a route requires authentication
  bool _requiresAuth(String route) {
    return !publicRoutes.contains(route) && !route.startsWith('/auth/callback');
  }

  /// Get the initial location based on current URI and platform
  String getInitialLocation() {
    final basePath = Uri.base.path;
    debugPrint('📍 Uri.base.path: $basePath');

    // For web, use current URL (important for OAuth callbacks)
    // For desktop/mobile, use login to avoid file system paths
    if (kIsWeb) {
      // Detect file system paths and redirect to login
      if (_isFileSystemPath(basePath)) {
        debugPrint('📍 Detected file system path, using login');
        return AppRoutes.login;
      }

      // If it's a valid route or OAuth callback, use it
      if (validRoutes.contains(basePath) || basePath.startsWith('/auth/callback')) {
        debugPrint('📍 Using current web path: $basePath');
        return basePath;
      }

      // If not valid, use login
      debugPrint('📍 Invalid web path, using login');
      return AppRoutes.login;
    } else {
      // On desktop/mobile, always use login
      debugPrint('📍 Desktop/mobile app, using login');
      return AppRoutes.login;
    }
  }

  /// Get the appropriate redirect for the current route and authentication state
  Future<String?> getRedirect(BuildContext context, String route) async {
    // Detect file system paths and redirect to login
    if (_isFileSystemPath(route)) {
      return AppRoutes.login;
    }

    // If path is empty or just "/", redirect to login
    if (route.isEmpty || route == '/') {
      return AppRoutes.login;
    }

    // Validate that the route is valid (unless it's an OAuth callback)
    if (!validRoutes.contains(route) && !route.startsWith('/auth/callback')) {
      return AppRoutes.login;
    }

    // Check authentication for protected routes
    if (_requiresAuth(route)) {
      final authBloc = context.read<AuthBloc>();
      final currentState = authBloc.state;

      // If currently loading, don't redirect yet
      if (currentState is AuthLoading || currentState is ProcessingCallback) {
        return null;
      }

      // If authenticated, allow access
      if (currentState is Authenticated) {
        return null;
      }

      // If not authenticated or error, redirect to login
      debugPrint('🔐 Authentication required, redirecting to login');
      return AppRoutes.login;
    }

    // No redirect needed
    return null;
  }

  /// Check if user is authenticated synchronously (best effort)
  Future<bool> isAuthenticated() async {
    final result = await _oauthRepository.isAuthenticated();
    return result.fold(
      onSuccess: (isAuth) => isAuth,
      onFailure: (_) => false,
    );
  }
}
