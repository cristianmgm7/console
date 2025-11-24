import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/generate_auth_url_usecase.dart';
import '../../domain/usecases/exchange_code_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/load_saved_token_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../../../core/di/injection.dart';
import '../../infrastructure/services/token_refresher_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@LazySingleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GenerateAuthUrlUseCase _generateAuthUrl;
  final ExchangeCodeUseCase _exchangeCode;
  final RefreshTokenUseCase _refreshToken;
  final LoadSavedTokenUseCase _loadSavedToken;
  final LogoutUseCase _logout;

  // Get TokenRefresherService lazily from service locator to break circular dependency
  TokenRefresherService get _tokenRefresher => getIt<TokenRefresherService>();

  AuthBloc(
    this._generateAuthUrl,
    this._exchangeCode,
    this._refreshToken,
    this._loadSavedToken,
    this._logout,
  ) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<OAuthCallbackReceived>(_onOAuthCallbackReceived);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loadSavedToken();

    result.fold(
      onSuccess: (token) {
        if (token == null) {
          emit(const Unauthenticated());
        } else if (token.isValid) {
          _tokenRefresher.startMonitoring();
          emit(const Authenticated());
        } else if (token.canRefresh) {
          add(const TokenRefreshRequested());
        } else {
          emit(const Unauthenticated());
        }
      },
      onFailure: (failure) {
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _generateAuthUrl();

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

  Future<void> _onOAuthCallbackReceived(
    OAuthCallbackReceived event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProcessingCallback());

    final result = await _exchangeCode(
      code: event.code,
      state: event.state,
    );

    result.fold(
      onSuccess: (token) {
        _tokenRefresher.startMonitoring();
        emit(const Authenticated(message: 'Login successful'));
      },
      onFailure: (failure) {
        emit(AuthError(FailureMapper.mapToMessage(failure.failure)));
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshToken();

    result.fold(
      onSuccess: (token) {
        emit(const Authenticated());
      },
      onFailure: (failure) {
        _tokenRefresher.stopMonitoring();
        emit(AuthError(FailureMapper.mapToMessage(failure.failure)));
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _tokenRefresher.stopMonitoring();

    final result = await _logout();

    result.fold(
      onSuccess: (_) => emit(const LoggedOut()),
      onFailure: (_) => emit(const LoggedOut()),
    );
  }

  @override
  Future<void> close() {
    _tokenRefresher.dispose();
    return super.close();
  }
}
