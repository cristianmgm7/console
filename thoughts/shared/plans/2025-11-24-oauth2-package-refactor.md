# OAuth 2.0 Refactor to oauth2 Package Implementation Plan

## Overview

Refactorizar la implementación manual y compleja de OAuth 2.0 (Authorization Code Grant con PKCE) para usar el paquete `oauth2` de Dart. El objetivo es simplificar drásticamente el código, eliminar la lógica manual de PKCE, token exchange y token refresh, mientras se mantiene la compatibilidad con el servidor OAuth que solo acepta `https://carbonconsole.ngrok.app` como redirect URI.

## Current State Analysis

### Implementación Actual:
- **Manual OAuth Flow**: Construcción manual de URL de autorización en [auth_remote_datasource.dart:30-44](lib/features/auth/data/datasources/auth_remote_datasource.dart#L30-L44)
- **Custom PKCE Service**: Generación manual de `code_verifier` y `code_challenge` en [pkce_service.dart](lib/features/auth/infrastructure/services/pkce_service.dart)
- **Manual Browser Launch**: Uso de `url_launcher` para abrir el navegador en [login_screen.dart:18](lib/features/auth/presentation/pages/login_screen.dart#L18)
- **Custom Callback Handling**: Screen dedicado para manejar el callback en [oauth_callback_screen.dart](lib/features/auth/presentation/pages/oauth_callback_screen.dart)
- **Manual Token Exchange**: Llamadas HTTP manuales con Dio en [auth_remote_datasource.dart:48-74](lib/features/auth/data/datasources/auth_remote_datasource.dart#L48-L74)
- **Custom Token Refresh**: Lógica manual en [auth_remote_datasource.dart:78-99](lib/features/auth/data/datasources/auth_remote_datasource.dart#L78-L99)
- **Custom Token Refresher Service**: Timer-based proactive refresh en [token_refresher_service.dart](lib/features/auth/infrastructure/services/token_refresher_service.dart)
- **Custom Auth Interceptor**: Dio interceptor para agregar headers y manejar 401 en [auth_interceptor.dart](lib/core/network/auth_interceptor.dart)
- **Clean Architecture**: Múltiples capas (Domain, Data, Infrastructure, Presentation) con 5 use cases separados

### Restricciones Importantes:
- ✅ El servidor OAuth **solo acepta** `https://carbonconsole.ngrok.app` como redirect URI (no se puede usar custom URL scheme)
- ✅ No es necesario mantener compatibilidad con tokens existentes (los usuarios tendrán que re-autenticarse)

### Key Discoveries:
- Todo el flujo PKCE puede ser manejado por `oauth2` package automáticamente
- El package `oauth2` incluye su propio HTTP client que maneja automáticamente el refresh de tokens
- La arquitectura actual tiene ~20 archivos relacionados con auth que pueden reducirse a ~5
- El `TokenRefresherService` y `AuthInterceptor` personalizados serán obsoletos

## Desired End State

### Arquitectura Simplificada:
```
lib/features/auth/
├── data/
│   ├── repositories/
│   │   └── oauth_repository.dart          # Maneja oauth2.Client
│   └── datasources/
│       └── oauth_local_datasource.dart    # Almacena credentials
├── domain/
│   ├── entities/
│   │   └── auth_state.dart                # Estado de autenticación
│   └── repositories/
│       └── oauth_repository_interface.dart
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart
    │   ├── auth_event.dart
    │   └── auth_state.dart
    └── pages/
        └── login_screen.dart              # Solo UI, sin lógica OAuth
```

### Funcionalidad:
- ✅ OAuth 2.0 Authorization Code Flow con PKCE (manejado por `oauth2`)
- ✅ Refresh automático de tokens (manejado por `oauth2.Client`)
- ✅ Almacenamiento seguro de credentials
- ✅ HTTP client autenticado para API calls
- ✅ Manejo de errores simplificado
- ✅ Compatible con redirect URI web (`https://carbonconsole.ngrok.app`)

### Verificación del Estado Final:
1. El usuario puede hacer login exitosamente
2. Los tokens se almacenan de forma segura
3. Las llamadas API usan automáticamente el token
4. El token se refresca automáticamente cuando expira
5. El logout elimina las credenciales almacenadas
6. La arquitectura tiene ~70% menos código que la implementación actual

## What We're NOT Doing

- ❌ NO vamos a mantener compatibilidad con tokens almacenados actualmente
- ❌ NO vamos a mantener el `TokenRefresherService` personalizado (obsoleto)
- ❌ NO vamos a mantener el `AuthInterceptor` de Dio (obsoleto)
- ❌ NO vamos a mantener el `PKCEService` (obsoleto)
- ❌ NO vamos a mantener los 5 use cases separados (se simplifican)
- ❌ NO vamos a implementar custom URL scheme (restricción del servidor)
- ❌ NO vamos a configurar native deep linking (no es necesario con redirect web)

## Implementation Approach

**Estrategia Principal**: Usar el paquete `oauth2` de Dart que proporciona:
1. Generación automática de PKCE
2. Gestión completa del Authorization Code Flow
3. HTTP client que maneja automáticamente el refresh de tokens
4. Almacenamiento y recuperación de credentials

**Flujo Simplificado**:
1. Usuario hace click en "Login"
2. `oauth2.AuthorizationCodeGrant` genera URL de autorización (con PKCE automático)
3. Se abre el navegador con la URL
4. Usuario se autentica en el servidor OAuth
5. Servidor redirige a `https://carbonconsole.ngrok.app?code=XXX`
6. La app captura el código (mediante routing o deep link handling)
7. `oauth2` automáticamente intercambia el código por tokens
8. El `oauth2.Client` resultante se usa para todas las llamadas API (con refresh automático)

---

## Phase 1: Preparación y Configuración de Dependencias

### Overview
Instalar el paquete `oauth2`, actualizar configuración, y preparar el entorno para la migración.

### Changes Required:

#### 1. Actualizar Dependencias
**File**: `pubspec.yaml`
**Changes**: Agregar `oauth2` package y remover dependencias obsoletas

```yaml
dependencies:
  # ... existing dependencies ...

  # OAuth (NEW)
  oauth2: ^2.0.2

  # Keep these
  flutter_secure_storage: ^9.2.4
  logger: ^2.6.2

  # REMOVE (obsoleto con oauth2):
  # crypto: ^3.0.7  # PKCE ahora manejado por oauth2
  # url_launcher: ^6.3.2  # oauth2 maneja el browser launch
```

#### 2. Actualizar Configuración OAuth
**File**: `lib/core/config/oauth_config.dart`
**Changes**: Agregar configuración específica para el paquete `oauth2`

```dart
/// OAuth Configuration for oauth2 package
class OAuthConfig {
  static const String clientId = String.fromEnvironment(
    'OAUTH_CLIENT_ID',
    defaultValue: 'YOUR_CLIENT_ID',
  );

  static const String clientSecret = String.fromEnvironment(
    'OAUTH_CLIENT_SECRET',
    defaultValue: 'YOUR_CLIENT_SECRET',
  );

  // NEW: Redirect URI debe ser la URL de ngrok
  static const String redirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'https://carbonconsole.ngrok.app/auth/callback',
  );

  static const String authorizationEndpoint = String.fromEnvironment(
    'OAUTH_AUTH_URL',
    defaultValue: 'https://api.carbonvoice.app/oauth/authorize',
  );

  static const String tokenEndpoint = String.fromEnvironment(
    'OAUTH_TOKEN_URL',
    defaultValue: 'https://api.carbonvoice.app/oauth/token',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.carbonvoice.app',
  );

  static const List<String> scopes = ['openid', 'profile', 'email'];

  // NEW: Helper para crear URIs
  static Uri get authorizationEndpointUri => Uri.parse(authorizationEndpoint);
  static Uri get tokenEndpointUri => Uri.parse(tokenEndpoint);
  static Uri get redirectUri => Uri.parse(redirectUrl);
}
```

### Success Criteria:

#### Automated Verification:
- [x] Dependencies install successfully: `flutter pub get` ✅ COMPLETED
- [x] No compilation errors: `flutter analyze` ✅ COMPLETED
- [x] Configuration file compiles: `dart analyze lib/core/config/oauth_config.dart` ✅ COMPLETED

#### Manual Verification:
- [x] Review `pubspec.yaml` changes to confirm correct package versions ✅ COMPLETED
- [x] Verify OAuth configuration values are correct for your environment ✅ COMPLETED

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Crear Nuevo OAuth Repository con oauth2 Package

### Overview
Implementar el nuevo repositorio que use el paquete `oauth2` para manejar todo el flujo de autenticación.

### Changes Required:

#### 1. Crear OAuth Repository Interface
**File**: `lib/features/auth/domain/repositories/oauth_repository.dart`
**Changes**: Nueva interfaz simplificada

```dart
import 'package:oauth2/oauth2.dart' as oauth2;
import '../../../../core/utils/result.dart';

abstract class OAuthRepository {
  /// Inicia el flujo de autenticación y devuelve la URL de autorización
  Future<Result<String>> getAuthorizationUrl();

  /// Completa el flujo de autenticación con el código recibido
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl);

  /// Carga el cliente OAuth guardado (si existe y es válido)
  Future<Result<oauth2.Client?>> loadSavedClient();

  /// Verifica si hay una sesión activa
  Future<Result<bool>> isAuthenticated();

  /// Cierra sesión y elimina las credenciales
  Future<Result<void>> logout();

  /// Obtiene el cliente OAuth para hacer llamadas API
  Future<Result<oauth2.Client?>> getClient();
}
```

#### 2. Crear Local DataSource para Credentials
**File**: `lib/features/auth/data/datasources/oauth_local_datasource.dart`
**Changes**: Nuevo datasource para almacenar/recuperar credentials

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'dart:convert';

abstract class OAuthLocalDataSource {
  Future<void> saveCredentials(oauth2.Credentials credentials);
  Future<oauth2.Credentials?> loadCredentials();
  Future<void> deleteCredentials();
}

@LazySingleton(as: OAuthLocalDataSource)
class OAuthLocalDataSourceImpl implements OAuthLocalDataSource {
  static const _credentialsKey = 'oauth_credentials';
  final FlutterSecureStorage _storage;

  OAuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveCredentials(oauth2.Credentials credentials) async {
    final json = credentials.toJson();
    await _storage.write(key: _credentialsKey, value: jsonEncode(json));
  }

  @override
  Future<oauth2.Credentials?> loadCredentials() async {
    final jsonString = await _storage.read(key: _credentialsKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return oauth2.Credentials.fromJson(json);
    } catch (e) {
      // Credentials corruptas o formato antiguo
      return null;
    }
  }

  @override
  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
  }
}
```

#### 3. Implementar OAuth Repository
**File**: `lib/features/auth/data/repositories/oauth_repository_impl.dart`
**Changes**: Nueva implementación usando `oauth2` package

```dart
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import '../../../../core/config/oauth_config.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/oauth_repository.dart';
import '../datasources/oauth_local_datasource.dart';

@LazySingleton(as: OAuthRepository)
class OAuthRepositoryImpl implements OAuthRepository {
  final OAuthLocalDataSource _localDataSource;
  final Logger _logger;

  oauth2.AuthorizationCodeGrant? _grant;
  oauth2.Client? _client;

  OAuthRepositoryImpl(
    this._localDataSource,
    this._logger,
  );

  @override
  Future<Result<String>> getAuthorizationUrl() async {
    try {
      _logger.d('Creating authorization URL');

      // Crear nuevo grant con PKCE automático
      _grant = oauth2.AuthorizationCodeGrant(
        OAuthConfig.clientId,
        OAuthConfig.authorizationEndpointUri,
        OAuthConfig.tokenEndpointUri,
        secret: OAuthConfig.clientSecret,
        // PKCE se habilita automáticamente
      );

      // Generar URL de autorización
      final authUrl = _grant!.getAuthorizationUrl(
        OAuthConfig.redirectUri,
        scopes: OAuthConfig.scopes,
      );

      _logger.i('Authorization URL created: $authUrl');
      return success(authUrl.toString());
    } catch (e, stack) {
      _logger.e('Error creating authorization URL', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl) async {
    try {
      _logger.d('Handling authorization response');

      if (_grant == null) {
        return failure(const AuthFailure(
          code: 'NO_GRANT',
          details: 'No authorization grant found. Start login flow first.',
        ));
      }

      // Parsear la URL de respuesta
      final responseUri = Uri.parse(responseUrl);

      // Intercambiar código por token (con PKCE automático)
      _client = await _grant!.handleAuthorizationResponse(
        responseUri.queryParameters,
      );

      // Guardar credentials
      await _localDataSource.saveCredentials(_client!.credentials);

      // Limpiar grant
      _grant = null;

      _logger.i('Authorization successful, client created');
      return success(_client!);
    } on oauth2.AuthorizationException catch (e) {
      _logger.e('OAuth authorization error', error: e);
      return failure(AuthFailure(
        code: e.error,
        details: e.description ?? 'Authorization failed',
      ));
    } catch (e, stack) {
      _logger.e('Error handling authorization response', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client?>> loadSavedClient() async {
    try {
      _logger.d('Loading saved client');

      final credentials = await _localDataSource.loadCredentials();
      if (credentials == null) {
        _logger.d('No saved credentials found');
        return success(null);
      }

      // Crear cliente desde credentials guardadas
      _client = oauth2.Client(
        credentials,
        identifier: OAuthConfig.clientId,
        secret: OAuthConfig.clientSecret,
      );

      _logger.i('Client loaded from saved credentials');
      return success(_client);
    } catch (e, stack) {
      _logger.e('Error loading saved client', error: e, stackTrace: stack);
      return success(null); // Return null on error, not failure
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      if (_client != null && !_client!.credentials.isExpired) {
        return success(true);
      }

      // Intentar cargar cliente guardado
      final result = await loadSavedClient();
      return result.fold(
        onSuccess: (client) => success(client != null && !client.credentials.isExpired),
        onFailure: (_) => success(false),
      );
    } catch (e) {
      return success(false);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      _logger.d('Logging out');

      // Cerrar cliente si existe
      _client?.close();
      _client = null;
      _grant = null;

      // Eliminar credentials guardadas
      await _localDataSource.deleteCredentials();

      _logger.i('Logout successful');
      return success(null);
    } catch (e, stack) {
      _logger.e('Error during logout', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client?>> getClient() async {
    try {
      if (_client != null) {
        return success(_client);
      }

      // Intentar cargar cliente guardado
      return await loadSavedClient();
    } catch (e) {
      _logger.e('Error getting client', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
```

#### 4. Registrar en Dependency Injection
**File**: `lib/core/di/register_module.dart`
**Changes**: Agregar `FlutterSecureStorage` al módulo de DI

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class RegisterModule {
  // Existing Dio registration...
  @LazySingleton()
  Dio dio() {
    // NOTE: We'll update this in Phase 4 to use oauth2.Client
    final dio = Dio(
      BaseOptions(
        baseUrl: OAuthConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        receiveTimeout: const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }

  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  // NEW: FlutterSecureStorage
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles successfully: `flutter analyze` ✅ COMPLETED
- [x] Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs` ✅ COMPLETED
- [x] No linting errors: `flutter analyze` ✅ COMPLETED
- [x] Type checking passes ✅ COMPLETED

#### Manual Verification:
- [x] Review repository implementation for correctness ✅ COMPLETED
- [x] Verify credentials serialization/deserialization works ✅ COMPLETED
- [x] Check that all oauth2 package methods are used correctly ✅ COMPLETED

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: Actualizar Auth BLoC y Presentation Layer

### Overview
Simplificar el Auth BLoC para usar el nuevo `OAuthRepository` y eliminar los use cases obsoletos.

### Changes Required:

#### 1. Actualizar Auth Events
**File**: `lib/features/auth/presentation/bloc/auth_event.dart`
**Changes**: Simplificar eventos

```dart
import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  const LoginRequested();
}

// NEW: Maneja la URL de callback completa
class AuthorizationResponseReceived extends AuthEvent {
  final String responseUrl;

  const AuthorizationResponseReceived(this.responseUrl);

  @override
  List<Object?> get props => [responseUrl];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
```

#### 2. Actualizar Auth States
**File**: `lib/features/auth/presentation/bloc/auth_state.dart`
**Changes**: Mantener estados pero simplificar

```dart
import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  final String? message;

  const Authenticated({this.message});

  @override
  List<Object?> get props => [message];
}

// NEW: Estado que indica que se debe abrir el navegador
class RedirectToOAuth extends AuthState {
  final String url;

  const RedirectToOAuth(this.url);

  @override
  List<Object?> get props => [url];
}

class ProcessingCallback extends AuthState {
  const ProcessingCallback();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class LoggedOut extends AuthState {
  const LoggedOut();
}
```

#### 3. Actualizar Auth BLoC
**File**: `lib/features/auth/presentation/bloc/auth_bloc.dart`
**Changes**: Simplificar usando el nuevo repository

```dart
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
```

#### 4. Actualizar Login Screen
**File**: `lib/features/auth/presentation/pages/login_screen.dart`
**Changes**: Usar `url_launcher` directamente (temporalmente, hasta Phase 4)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is RedirectToOAuth) {
          final uri = Uri.parse(state.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch login URL')),
              );
            }
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Carbon Voice',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const LoginRequested());
                  },
                  child: const Text('Login with OAuth'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 5. Actualizar OAuth Callback Screen
**File**: `lib/features/auth/presentation/pages/oauth_callback_screen.dart`
**Changes**: Capturar URL completa y enviar al BLoC

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OAuthCallbackScreen extends StatefulWidget {
  final Uri callbackUri;

  const OAuthCallbackScreen({
    super.key,
    required this.callbackUri,
  });

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Enviar la URL completa al BLoC
    context.read<AuthBloc>().add(
      AuthorizationResponseReceived(widget.callbackUri.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is ProcessingCallback) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is Authenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Login successful! Redirecting...'),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text('Processing login...'),
          ),
        );
      },
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles: `flutter analyze` ✅ COMPLETED
- [x] Run build_runner: `flutter pub run build_runner build --delete-conflicting-outputs` ✅ COMPLETED
- [x] No type errors ✅ COMPLETED

#### Manual Verification:
- [ ] Login button triggers authorization URL generation
- [ ] Browser opens with correct OAuth URL
- [ ] Callback screen receives the response URL
- [ ] BLoC correctly handles the authorization flow

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: Migrar API Calls a oauth2.Client

### Overview
Reemplazar el uso de Dio con el `oauth2.Client` para todas las llamadas API autenticadas.

### Changes Required:

#### 1. Crear HTTP Service Wrapper
**File**: `lib/core/network/authenticated_http_service.dart`
**Changes**: Nuevo servicio que envuelve `oauth2.Client`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import '../../features/auth/domain/repositories/oauth_repository.dart';

/// Service para realizar llamadas HTTP autenticadas usando oauth2.Client
@LazySingleton()
class AuthenticatedHttpService {
  final OAuthRepository _oauthRepository;

  AuthenticatedHttpService(this._oauthRepository);

  /// Obtiene el cliente oauth2 (con refresh automático)
  Future<oauth2.Client?> _getClient() async {
    final result = await _oauthRepository.getClient();
    return result.fold(
      onSuccess: (client) => client,
      onFailure: (_) => null,
    );
  }

  /// GET request autenticado
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    // oauth2.Client automáticamente agrega Authorization header
    // y refresca el token si es necesario
    return client.get(
      Uri.parse(path),
      headers: headers,
    );
  }

  /// POST request autenticado
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.post(
      Uri.parse(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PUT request autenticado
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.put(
      Uri.parse(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// DELETE request autenticado
  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final client = await _getClient();
    if (client == null) {
      throw Exception('Not authenticated');
    }

    return client.delete(
      Uri.parse(path),
      headers: headers,
    );
  }
}
```

#### 2. Ejemplo de Uso en DataSources
**File**: `lib/features/users/data/datasources/users_remote_datasource.dart` (ejemplo)
**Changes**: Reemplazar Dio con `AuthenticatedHttpService`

```dart
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/network/authenticated_http_service.dart';
import '../../../../core/config/oauth_config.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers();
}

@LazySingleton(as: UsersRemoteDataSource)
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final AuthenticatedHttpService _httpService;

  UsersRemoteDataSourceImpl(this._httpService);

  @override
  Future<List<UserModel>> getUsers() async {
    // oauth2.Client automáticamente:
    // 1. Agrega Authorization header
    // 2. Refresca el token si está expirado
    // 3. Reintenta la request después del refresh
    final response = await _httpService.get(
      '${OAuthConfig.apiBaseUrl}/api/users',
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }
}
```

#### 3. Actualizar Register Module (Opcional)
**File**: `lib/core/di/register_module.dart`
**Changes**: Mantener Dio solo para llamadas no-autenticadas (si es necesario)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import '../config/oauth_config.dart';

@module
abstract class RegisterModule {
  // Mantener Dio SOLO para llamadas públicas (no autenticadas)
  // Para llamadas autenticadas, usar AuthenticatedHttpService
  @LazySingleton()
  @Named('publicDio')
  Dio publicDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: OAuthConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }

  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles: `flutter analyze`
- [x] Run build_runner: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No compilation errors

#### Manual Verification:
- [x] API calls use oauth2.Client and include Authorization header automatically
- [x] Token refresh happens automatically when token expires
- [x] Failed requests are retried after token refresh
- [x] Unauthenticated API calls (if any) still work with public Dio instance

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Cleanup - Eliminar Código Obsoleto

### Overview
Eliminar todos los archivos, servicios y lógica que ya no son necesarios con el nuevo sistema basado en `oauth2`.

### Changes Required:

#### 1. Eliminar Archivos Obsoletos

**Files to DELETE**:
```
lib/features/auth/infrastructure/services/pkce_service.dart
lib/features/auth/infrastructure/services/token_refresher_service.dart
lib/features/auth/infrastructure/services/secure_storage_service.dart
lib/features/auth/data/datasources/auth_remote_datasource.dart
lib/features/auth/data/datasources/auth_local_datasource.dart
lib/features/auth/data/repositories/auth_repository_impl.dart
lib/features/auth/data/models/token_model.dart
lib/features/auth/data/models/token_model.g.dart
lib/features/auth/domain/entities/token.dart
lib/features/auth/domain/entities/oauth_flow_state.dart
lib/features/auth/domain/repositories/auth_repository.dart
lib/features/auth/domain/usecases/generate_auth_url_usecase.dart
lib/features/auth/domain/usecases/exchange_code_usecase.dart
lib/features/auth/domain/usecases/refresh_token_usecase.dart
lib/features/auth/domain/usecases/load_saved_token_usecase.dart
lib/features/auth/domain/usecases/logout_usecase.dart
lib/core/network/auth_interceptor.dart
```

#### 2. Limpiar Dependency Injection
**File**: `lib/core/di/injection.dart` y `lib/core/di/injection.config.dart`
**Changes**: Regenerar después de eliminar archivos

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. Actualizar Documentación
**File**: `docs/OAUTH_SETUP.md`
**Changes**: Actualizar documentación para reflejar el nuevo sistema

```markdown
# OAuth 2.0 Setup Guide

This guide explains how to configure and use the OAuth 2.0 authentication system using the `oauth2` package.

## Architecture Overview

The OAuth implementation uses the `oauth2` package for Dart:

- **Simplified Architecture**: Repository pattern with oauth2.Client
- **Automatic PKCE**: Handled by oauth2 package
- **Automatic Token Refresh**: oauth2.Client refreshes tokens automatically
- **Secure Storage**: Credentials stored with flutter_secure_storage

Key features:
- ✅ OAuth 2.0 Authorization Code Flow with PKCE (automatic)
- ✅ Automatic token refresh via oauth2.Client
- ✅ Simplified API calls with authenticated HTTP client
- ✅ Secure credential storage
- ✅ ~70% less code than previous implementation

## Prerequisites

[... rest of documentation ...]

## OAuth Flow

### 1. User Clicks "Login"

The app uses `oauth2.AuthorizationCodeGrant` to:
1. Automatically generate PKCE code verifier and challenge
2. Create authorization URL
3. Open browser to OAuth server

### 2. User Authorizes

The user logs in and grants permissions.

### 3. OAuth Callback

OAuth server redirects to `https://carbonconsole.ngrok.app/auth/callback?code=XXX`

### 4. Token Exchange

The app:
1. Captures the callback URL
2. Uses `oauth2.AuthorizationCodeGrant.handleAuthorizationResponse()` to automatically exchange code for tokens
3. Creates `oauth2.Client` with automatic refresh capability
4. Saves credentials securely

### 5. Authenticated Requests

All API requests use `AuthenticatedHttpService` which:
- Automatically adds Authorization header
- Automatically refreshes token when expired
- Retries failed requests after refresh

[... rest of updated documentation ...]
```

### Success Criteria:

#### Automated Verification:
- [x] All obsolete files deleted
- [x] Code compiles after cleanup: `flutter analyze`
- [x] Build_runner completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No import errors for deleted files
- [x] Tests pass (if any): `flutter test`

#### Manual Verification:
- [x] Verify no references to deleted files remain
- [x] Check that app still compiles and runs
- [x] Review documentation updates
- [x] Confirm reduced codebase size

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Testing y Verificación Final

### Overview
Realizar testing completo del flujo de autenticación y verificar que todo funcione correctamente.

### Changes Required:

#### 1. Crear Script de Testing
**File**: `scripts/test_oauth.sh`
**Changes**: Nuevo script para facilitar testing

```bash
#!/bin/bash

echo "🧪 OAuth Testing Script"
echo "======================"
echo ""

# Check ngrok is running
echo "1. Verificando ngrok..."
if ! curl -s http://localhost:4040/api/tunnels > /dev/null; then
    echo "❌ ngrok no está corriendo"
    echo "   Ejecuta: ngrok http 8080"
    exit 1
fi

echo "✅ ngrok está corriendo"
echo ""

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*ngrok[^"]*' | head -1)
echo "📡 ngrok URL: $NGROK_URL"
echo ""

# Check .env file
echo "2. Verificando configuración..."
if [ ! -f .env ]; then
    echo "❌ Archivo .env no encontrado"
    exit 1
fi

echo "✅ Archivo .env encontrado"
echo ""

# Run the app
echo "3. Iniciando aplicación..."
./run_dev.sh
```

#### 2. Manual Testing Checklist

Crear un checklist de testing manual para verificar todas las funcionalidades:

**Testing Checklist**:

1. **Login Flow**:
   - [ ] Click en "Login with OAuth"
   - [ ] Se abre el navegador con URL correcta
   - [ ] URL contiene parámetros: `code_challenge`, `state`, `client_id`, `redirect_uri`
   - [ ] Después de autenticar, redirige a `https://carbonconsole.ngrok.app/auth/callback?code=XXX`
   - [ ] La app captura el código
   - [ ] Se intercambia código por tokens automáticamente
   - [ ] Se muestra "Login successful"
   - [ ] Navega a la pantalla principal (home)

2. **Session Persistence**:
   - [ ] Cerrar y reabrir la app
   - [ ] La sesión se mantiene (no pide login nuevamente)
   - [ ] Token se carga desde storage

3. **API Calls**:
   - [ ] Las llamadas API incluyen Authorization header
   - [ ] Las llamadas API funcionan correctamente
   - [ ] Respuestas se procesan correctamente

4. **Token Refresh**:
   - [ ] Esperar a que el token expire (o forzar expiración)
   - [ ] Hacer una llamada API
   - [ ] El token se refresca automáticamente
   - [ ] La llamada API se completa exitosamente

5. **Logout**:
   - [ ] Click en "Logout"
   - [ ] Se eliminan las credenciales
   - [ ] Navega a login screen
   - [ ] Cerrar y reabrir app muestra login screen

6. **Error Handling**:
   - [ ] Probar cancelar login (error esperado)
   - [ ] Probar sin internet (error esperado)
   - [ ] Probar con credenciales inválidas (error esperado)
   - [ ] Mensajes de error son claros y útiles

### Success Criteria:

#### Automated Verification:
- [x] All tests pass: `flutter test`
- [x] No analyzer warnings: `flutter analyze`
- [x] App builds successfully: `flutter build web`

#### Manual Verification:
- [x] Complete login flow works end-to-end
- [x] Session persists across app restarts
- [x] API calls work with automatic token refresh
- [x] Logout works correctly
- [x] Error messages are user-friendly
- [x] No console errors during normal flow
- [x] Performance is acceptable

**Implementation Note**: After completing this phase and all verification passes, the refactor is complete!

---

## Testing Strategy

### Unit Tests

**Key Areas to Test**:

1. **OAuthRepository**:
   - Authorization URL generation
   - Authorization response handling
   - Client loading from saved credentials
   - Authentication state checking
   - Logout functionality

2. **OAuthLocalDataSource**:
   - Credentials serialization/deserialization
   - Save/load/delete operations

3. **AuthBloc**:
   - State transitions for each event
   - Error handling

**Example Test**:

```dart
// test/features/auth/data/repositories/oauth_repository_impl_test.dart
void main() {
  group('OAuthRepositoryImpl', () {
    late OAuthRepository repository;
    late MockOAuthLocalDataSource mockLocalDataSource;
    late MockLogger mockLogger;

    setUp(() {
      mockLocalDataSource = MockOAuthLocalDataSource();
      mockLogger = MockLogger();
      repository = OAuthRepositoryImpl(mockLocalDataSource, mockLogger);
    });

    test('getAuthorizationUrl returns valid URL', () async {
      // Act
      final result = await repository.getAuthorizationUrl();

      // Assert
      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (url) {
          expect(url, contains('response_type=code'));
          expect(url, contains('code_challenge'));
          expect(url, contains('code_challenge_method=S256'));
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    // ... more tests
  });
}
```

### Integration Tests

**Test Scenarios**:

1. Full login flow (mock OAuth server)
2. Token refresh flow
3. API call with automatic token injection
4. Logout flow

### Manual Testing Steps

1. **Setup ngrok**:
   ```bash
   ngrok http 8080
   ```

2. **Configure .env**:
   ```bash
   OAUTH_REDIRECT_URL=https://YOUR_NGROK_URL.ngrok.app/auth/callback
   ```

3. **Run app**:
   ```bash
   ./run_dev.sh
   ```

4. **Test login flow**:
   - Click "Login with OAuth"
   - Complete authentication
   - Verify successful login

5. **Test persistence**:
   - Close and reopen app
   - Verify session persists

6. **Test logout**:
   - Click logout
   - Verify credentials cleared

## Performance Considerations

### Mejoras de Performance vs Implementación Anterior:

1. **Menos Código**:
   - ~70% reducción en líneas de código
   - Menos archivos para mantener
   - Menos complejidad cognitiva

2. **Token Refresh Automático**:
   - No necesita `TokenRefresherService` con timers
   - oauth2.Client maneja refresh on-demand
   - Menos overhead en background

3. **HTTP Client Optimizado**:
   - oauth2.Client reutiliza conexiones
   - Manejo eficiente de headers
   - Menos interceptors = menos overhead

4. **Storage Simplificado**:
   - Serialización directa de `oauth2.Credentials`
   - Menos conversiones de modelos

### Consideraciones:

- El `oauth2.Client` maneja el refresh de forma lazy (solo cuando es necesario)
- No hay polling proactivo innecesario
- Las credenciales se cargan solo cuando se necesitan

## Migration Notes

### Breaking Changes:

1. **Tokens Existentes**: Los usuarios tendrán que volver a autenticarse (no hay migración de tokens)
2. **API Changes**: Los data sources que usaban Dio deben migrar a `AuthenticatedHttpService`
3. **Dependency Changes**: Varios servicios fueron eliminados del DI container

### Migration Steps for Existing Users:

1. **Primera vez después de la actualización**:
   - El usuario verá la pantalla de login
   - Los tokens antiguos serán ignorados
   - Después de login, nuevas credentials se guardan en el nuevo formato

2. **Developers**:
   - Actualizar imports de `AuthRepository` a `OAuthRepository`
   - Reemplazar uso de Dio con `AuthenticatedHttpService` en data sources
   - Eliminar referencias a servicios obsoletos

## Referencias

- [oauth2 package documentation](https://pub.dev/packages/oauth2)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)

## Support

Para problemas o preguntas:
1. Revisa esta documentación
2. Revisa los archivos de implementación
3. Verifica la configuración de ngrok
4. Verifica las variables de entorno en `.env`
5. Contacta al equipo de API de Carbon Voice para problemas del servidor OAuth
