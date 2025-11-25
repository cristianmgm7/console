import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {

  AuthBloc(this._oauthRepository) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<AuthorizationResponseReceived>(_onAuthorizationResponseReceived);
    on<LogoutRequested>(_onLogoutRequested);
  }
  final OAuthRepository _oauthRepository;

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

          // NO redirigir a login si estamos en el callback route
          // El router manejará la navegación
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
      onSuccess: (_) => emit(const Unauthenticated()),
      onFailure: (_) => emit(const Unauthenticated()),
    );
  }
}
