import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/oauth_repository.dart';
import '../../../../core/utils/failure_mapper.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@LazySingleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final OAuthRepository _oauthRepository;

  AuthBloc(this._oauthRepository) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<AuthorizationResponseReceived>(_onAuthorizationResponseReceived);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    print('🟡 AuthBloc: AppStarted event received');
    print('🟡 AuthBloc: Current URL path: ${Uri.base.path}');

    emit(const AuthLoading());
    print('🟡 AuthBloc: Emitted AuthLoading state');

    final result = await _oauthRepository.isAuthenticated();

    result.fold(
      onSuccess: (isAuthenticated) {
        print('🟡 AuthBloc: isAuthenticated check result: $isAuthenticated');
        if (isAuthenticated) {
          print(
              '🟢 AuthBloc: User is authenticated, emitting Authenticated state');
          emit(const Authenticated());
        } else {
          print(
              '🟡 AuthBloc: User is not authenticated, emitting Unauthenticated state');
          // NO redirigir a login si estamos en el callback route
          // El router manejará la navegación
          emit(const Unauthenticated());
        }
      },
      onFailure: (_) {
        print(
            '🔴 AuthBloc: Error checking authentication, emitting Unauthenticated state');
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🟡 AuthBloc: LoginRequested event received');
    final result = await _oauthRepository.getAuthorizationUrl();

    result.fold(
      onSuccess: (url) {
        print('🟢 AuthBloc: Authorization URL created: $url');
        print('🟢 AuthBloc: Emitting RedirectToOAuth state');
        emit(RedirectToOAuth(url));
      },
      onFailure: (failure) {
        print('🔴 AuthBloc: Failed to create authorization URL');
        print(
            '🔴 AuthBloc: Error: ${FailureMapper.mapToMessage(failure.failure)}');
        emit(AuthError(FailureMapper.mapToMessage(failure.failure)));
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onAuthorizationResponseReceived(
    AuthorizationResponseReceived event,
    Emitter<AuthState> emit,
  ) async {
    print('🟡 AuthBloc: AuthorizationResponseReceived event received');
    print('🟡 AuthBloc: Response URL: ${event.responseUrl}');

    emit(const ProcessingCallback());
    print('🟡 AuthBloc: Emitted ProcessingCallback state');

    final result = await _oauthRepository.handleAuthorizationResponse(
      event.responseUrl,
    );

    result.fold(
      onSuccess: (_) {
        print(
            '🟢 AuthBloc: Token exchange successful! Emitting Authenticated state');
        emit(const Authenticated(message: 'Login successful'));
      },
      onFailure: (failure) {
        print('🔴 AuthBloc: Token exchange failed!');
        print('🔴 AuthBloc: Failure: ${failure.failure}');
        print(
            '🔴 AuthBloc: Error message: ${FailureMapper.mapToMessage(failure.failure)}');
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
