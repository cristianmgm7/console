# OAuth 2.0 Setup Guide

This guide explains how to configure and use the OAuth 2.0 authentication system in the Carbon Voice Console app.

## Architecture Overview

The OAuth implementation follows **Clean Architecture** principles:

- **Domain Layer**: Pure business logic (use cases, entities, repository interfaces)
- **Data Layer**: Implementation of repositories, data sources (remote/local)
- **Infrastructure Layer**: Platform-specific services (PKCE, secure storage, token refresh)
- **Presentation Layer**: UI (BLoC, screens)

Key features:
- ✅ OAuth 2.0 Authorization Code Flow with PKCE
- ✅ Sealed `Result<T>` type for type-safe error handling
- ✅ Automatic token refresh (60s before expiry)
- ✅ Centralized HTTP interceptor for 401 handling
- ✅ UI-friendly error mapping with i18n support
- ✅ Secure token storage

## Prerequisites

1. **Client Credentials**: Obtain from Carbon Voice API team
   - Client ID
   - Client Secret

2. **Redirect URL**: Must be registered with Carbon Voice
   - For web: `https://yourdomain.com/auth/callback`
   - For development: Use ngrok to expose local server

3. **Environment Setup**: Flutter SDK installed

## Configuration

### 1. Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Fill in your credentials in `.env`:

```bash
# Client Credentials (from Carbon Voice API team)
OAUTH_CLIENT_ID=your_client_id_here
OAUTH_CLIENT_SECRET=your_client_secret_here

# Redirect URL (must match what you registered)
OAUTH_REDIRECT_URL=https://carbonconsole.ngrok.app/auth/callback

# OAuth Endpoints
OAUTH_AUTH_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token

# API Base URL
API_BASE_URL=https://api.carbonvoice.app
```

### 2. OAuth Configuration

The app uses `String.fromEnvironment()` to read configuration at compile time from `--dart-define` flags.

See [lib/core/config/oauth_config.dart](../lib/core/config/oauth_config.dart) for the configuration class.

## Running the App

### Development Mode

Use the provided script that automatically loads environment variables:

```bash
./run_dev.sh
```

This script:
1. Loads variables from `.env`
2. Passes them as `--dart-define` flags to Flutter
3. Runs the app in Chrome

### Manual Run

If you prefer to run manually:

```bash
flutter run -d chrome \
  --dart-define=OAUTH_CLIENT_ID="your_client_id" \
  --dart-define=OAUTH_CLIENT_SECRET="your_client_secret" \
  --dart-define=OAUTH_REDIRECT_URL="your_redirect_url" \
  --dart-define=OAUTH_AUTH_URL="https://api.carbonvoice.app/oauth/authorize" \
  --dart-define=OAUTH_TOKEN_URL="https://api.carbonvoice.app/oauth/token" \
  --dart-define=API_BASE_URL="https://api.carbonvoice.app"
```

## Building for Production

### Web Build

Use the provided build script:

```bash
./build_web.sh
```

This creates an optimized production build in `build/web/` with all environment variables baked in.

### Important Security Notes

⚠️ **NEVER commit `.env` to Git!** (It's in `.gitignore`)

⚠️ **Client secrets in web apps**: Since JavaScript runs in the browser, the client secret will be visible in the compiled code. This is acceptable for OAuth 2.0 Authorization Code Flow with PKCE, as:
- PKCE provides additional security
- The authorization server validates the redirect URL
- Tokens are short-lived and automatically refreshed

For higher security environments, consider using a backend proxy that handles token exchange.

## OAuth Flow

### 1. User Clicks "Login"

```dart
context.read<AuthBloc>().add(const LoginRequested());
```

The app:
1. Generates PKCE code verifier and challenge
2. Creates authorization URL with `code_challenge`
3. Opens browser to Carbon Voice authorization page

### 2. User Authorizes

The user logs in at Carbon Voice and grants permissions.

### 3. OAuth Callback

Carbon Voice redirects back to `OAUTH_REDIRECT_URL` with:
- `code`: Authorization code
- `state`: CSRF protection token

The app's `/auth/callback` route receives these parameters.

### 4. Token Exchange

```dart
context.read<AuthBloc>().add(OAuthCallbackReceived(
  code: code,
  state: state,
));
```

The app:
1. Validates the `state` parameter (CSRF protection)
2. Exchanges the `code` for an access token using PKCE `code_verifier`
3. Saves the token securely
4. Starts background token refresh monitoring

### 5. Authenticated Requests

All API requests automatically include the access token via `AuthInterceptor`:

```dart
// Dio automatically adds: Authorization: Bearer <access_token>
final response = await dio.get('/api/users');
```

### 6. Automatic Token Refresh

Two refresh mechanisms work together:

**Proactive Refresh** (`TokenRefresherService`):
- Refreshes token 60 seconds before expiry
- Runs in background while app is active
- Pauses when app goes to background

**Reactive Refresh** (`AuthInterceptor`):
- Intercepts 401 responses
- Attempts token refresh
- Retries the failed request with new token

## Architecture Components

### Core Types

#### Result<T> ([lib/core/utils/result.dart](../lib/core/utils/result.dart))

```dart
sealed class Result<T> {
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  });
}

// Usage
final result = await useCase();
result.fold(
  onSuccess: (data) => print(data),
  onFailure: (failure) => print(failure.failure),
);
```

#### Failures ([lib/core/errors/failures.dart](../lib/core/errors/failures.dart))

Sealed hierarchy of domain failures:
- `TokenExpiredFailure`
- `InvalidCredentialsFailure`
- `InvalidStateFailure`
- `NetworkFailure`
- `ServerFailure`
- etc.

#### FailureMapper ([lib/core/utils/failure_mapper.dart](../lib/core/utils/failure_mapper.dart))

Maps domain failures to user-friendly messages (i18n-ready):

```dart
final message = FailureMapper.mapToMessage(failure);
// "Your session has expired. Please login again."
```

### Domain Layer

#### Use Cases

Each use case encapsulates one business operation:

- `GenerateAuthUrlUseCase`: Creates authorization URL
- `ExchangeCodeUseCase`: Exchanges code for token (with state validation)
- `RefreshTokenUseCase`: Refreshes access token
- `LoadSavedTokenUseCase`: Loads saved token from storage
- `LogoutUseCase`: Revokes token and clears storage

#### Repository Interface

```dart
abstract class AuthRepository {
  Future<Result<String>> generateAuthorizationUrl();
  Future<Result<Token>> exchangeCodeForToken({...});
  Future<Result<Token>> refreshToken(String refreshToken);
  // ...
}
```

### Data Layer

#### Remote Data Source

Handles HTTP communication with OAuth server using Dio.

#### Local Data Source

Manages secure token storage using `flutter_secure_storage`.

#### Repository Implementation

Implements `AuthRepository`, orchestrates data sources, maps exceptions to failures.

### Infrastructure Layer

#### PKCEService

Generates cryptographically secure PKCE parameters:
- Code verifier (random 128-character string)
- Code challenge (SHA-256 hash, base64url encoded)
- State parameter (CSRF token)

#### TokenRefresherService

Monitors token expiry and proactively refreshes:

```dart
@LazySingleton()
class TokenRefresherService {
  Future<void> startMonitoring();
  void stopMonitoring();
  Future<void> resume();
  void pause();
}
```

#### AuthInterceptor

Dio interceptor that:
1. Adds `Authorization` header to requests
2. Intercepts 401 responses
3. Refreshes token
4. Retries failed request

### Presentation Layer

#### AuthBloc

Coordinates authentication flow:

```dart
@LazySingleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Events: AppStarted, LoginRequested, OAuthCallbackReceived, etc.
  // States: Unauthenticated, Authenticated, AuthLoading, etc.
}
```

#### Screens

- `LoginScreen`: Shows login button
- `OAuthCallbackScreen`: Handles OAuth redirect

## Testing the Flow

### 1. Setup ngrok (for local development)

```bash
ngrok http 8080
```

Use the generated URL as your `OAUTH_REDIRECT_URL`:
```
https://abc123.ngrok.app/auth/callback
```

### 2. Run the App

```bash
./run_dev.sh
```

### 3. Click "Login with OAuth"

The browser opens Carbon Voice authorization page.

### 4. Authorize

Log in and grant permissions.

### 5. Verify Redirect

You should be redirected back to `/auth/callback` and see "Login successful!"

### 6. Check Token Storage

The access token is saved securely and automatically used for API calls.

### 7. Test Token Refresh

Wait for the token to near expiry (or manually trigger refresh) to verify automatic refresh works.

## Troubleshooting

### "Invalid redirect_uri"

**Problem**: The redirect URL doesn't match what's registered with Carbon Voice.

**Solution**:
- Verify `OAUTH_REDIRECT_URL` in `.env` matches exactly
- Ensure it's registered with Carbon Voice API team
- Check for trailing slashes or http vs https

### "Invalid state parameter"

**Problem**: CSRF token mismatch.

**Solution**:
- Clear browser cache/cookies
- Restart the app
- Check if multiple OAuth flows are running simultaneously

### "Token refresh failed"

**Problem**: Refresh token is invalid or expired.

**Solution**:
- Log out and log back in
- Check if refresh token was properly saved
- Verify `OAUTH_TOKEN_URL` is correct

### "Network error"

**Problem**: Can't reach OAuth server.

**Solution**:
- Check internet connection
- Verify `API_BASE_URL`, `OAUTH_AUTH_URL`, `OAUTH_TOKEN_URL` are correct
- Check if Carbon Voice API is accessible

### Build fails with "String.fromEnvironment not found"

**Problem**: Environment variables not passed correctly.

**Solution**:
- Use `./run_dev.sh` or `./build_web.sh` scripts
- Ensure all `--dart-define` flags are provided
- Check `.env` file exists and has all variables

## API Endpoints

The OAuth server should support these endpoints:

### Authorization Endpoint
```
GET https://api.carbonvoice.app/oauth/authorize
  ?response_type=code
  &client_id={client_id}
  &redirect_uri={redirect_uri}
  &code_challenge={code_challenge}
  &code_challenge_method=S256
  &state={state}
  &scope=openid profile email
```

### Token Endpoint
```
POST https://api.carbonvoice.app/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&client_id={client_id}
&client_secret={client_secret}
&code={authorization_code}
&redirect_uri={redirect_uri}
&code_verifier={code_verifier}
```

### Token Refresh
```
POST https://api.carbonvoice.app/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&client_id={client_id}
&client_secret={client_secret}
&refresh_token={refresh_token}
```

### Token Revocation (Optional)
```
POST https://api.carbonvoice.app/oauth/revoke
Content-Type: application/x-www-form-urlencoded

token={access_token}
&client_id={client_id}
&client_secret={client_secret}
```

## Security Checklist

- ✅ PKCE (Proof Key for Code Exchange) enabled
- ✅ State parameter for CSRF protection
- ✅ Secure token storage (flutter_secure_storage)
- ✅ Short-lived access tokens with automatic refresh
- ✅ No tokens in URL query parameters
- ✅ HTTPS for all OAuth endpoints
- ✅ `.env` file in `.gitignore`

## References

- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Dio HTTP Client](https://pub.dev/packages/dio)

## Support

For issues or questions:
1. Check this documentation
2. Review the plan: [thoughts/shared/plans/2025-11-23-oauth2-clean-architecture-v2.md](../thoughts/shared/plans/2025-11-23-oauth2-clean-architecture-v2.md)
3. Check implementation files referenced above
4. Contact Carbon Voice API team for OAuth server issues
