import 'package:carbon_voice_console/core/errors/failure_mapper.dart';
import 'package:carbon_voice_console/core/services/deep_linking_service.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {

  AuthBloc(this._oauthRepository, this._deepLinkingService) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<AuthorizationResponseReceived>(_onAuthorizationResponseReceived);
    on<LogoutRequested>(_onLogoutRequested);

    // Setup deep link handler for desktop OAuth callbacks
    if (!kIsWeb) {
      _deepLinkingService.setDeepLinkHandler((url) {
        add(AuthorizationResponseReceived(url));
      });
    }
  }
  final OAuthRepository _oauthRepository;
  final DeepLinkingService _deepLinkingService;

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {

    emit(const AuthLoading());

    final result = await _oauthRepository.isAuthenticated();
    
    result.fold(
      onSuccess: (isAuthenticated) {

        if (isAuthenticated) {

          emit(const Authenticated());
        } else {
          // Do NOT redirect to login if we are on the callback route
          // The router will handle navigation
          emit(const Unauthenticated());
        }
      },
      onFailure: (_) {

        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    if (kIsWeb) {
      // Web flow: Get URL and redirect
      final result = await _oauthRepository.getAuthorizationUrl();
      result.fold(
        onSuccess: (url) {
          emit(RedirectToOAuth(url));
        },
        onFailure: (failure) {
          emit(AuthError(FailureMapper.mapToMessage(failure.failure)));
          emit(const Unauthenticated());
        },
      );
    } else {
      // Desktop flow: Open browser and wait for deep link callback
      final result = await _oauthRepository.loginWithDesktop();
      result.fold(
        onSuccess: (_) {
          // Should not happen - desktop flow returns PENDING failure
          emit(const Authenticated(message: 'Login successful'));
        },
        onFailure: (error) {
          // PENDING means browser opened successfully, waiting for callback
          if (error.failure.toString().contains('PENDING')) {
            emit(const AuthLoading());
          } else {
            emit(AuthError(FailureMapper.mapToMessage(error.failure)));
            emit(const Unauthenticated());
          }
        },
      );
    }
  }

  Future<void> _onAuthorizationResponseReceived(
    AuthorizationResponseReceived event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProcessingCallback());
    final result = await _oauthRepository.handleAuthorizationResponse(
      event.responseUrl,
    );
    result.fold(
      onSuccess: (_) {
        emit(const Authenticated(message: 'Login successful'));
      },
      onFailure: (failure) {
        emit(AuthError(FailureMapper.mapToMessage(failure.failure)));
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _oauthRepository.logout();
    result.fold(
      onSuccess: (_) => emit(const LoggedOut()),
      onFailure: (_) => emit(const LoggedOut()),
    );
  }
}
