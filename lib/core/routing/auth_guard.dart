import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Service to guard routes that require authentication
class AuthGuard {
  AuthGuard(this._oauthRepository);

  final OAuthRepository _oauthRepository;

  /// Routes that don't require authentication
  static const List<String> publicRoutes = [
    AppRoutes.login,
    AppRoutes.oauthCallback,
  ];

  /// Check if a route requires authentication
  bool requiresAuth(String route) {
    return !publicRoutes.contains(route) && !route.startsWith('/auth/callback');
  }

  /// Get the appropriate redirect for the current authentication state
  Future<String?> getRedirect(BuildContext context, String route) async {
    // If it's a public route, no redirect needed
    if (!requiresAuth(route)) {
      return null;
    }

    // Check authentication status
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
    return AppRoutes.login;
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

/// Factory function to get AuthGuard instance
AuthGuard getAuthGuard() => AuthGuard(getIt<OAuthRepository>());
