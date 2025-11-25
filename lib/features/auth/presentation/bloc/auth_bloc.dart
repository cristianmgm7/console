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
    emit(const AuthLoading());

    final result = await _oauthRepository.isAuthenticated();

    result.fold(
      onSuccess: (isAuthenticated) {
        if (isAuthenticated) {
          emit(const Authenticated());
        } else {
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
