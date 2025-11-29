import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

abstract class OAuthRepository {
  /// Starts the authentication flow and returns the authorization URL
  Future<Result<String>> getAuthorizationUrl();

  /// Completes the authentication flow with the received code
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl);

  /// Desktop OAuth flow - handles everything including opening browser
  /// Only available on desktop platforms (macOS, Windows, Linux)
  Future<Result<oauth2.Client>> loginWithDesktop();

  /// Loads the saved OAuth client (if it exists and is valid)
  Future<Result<oauth2.Client?>> loadSavedClient();

  /// Checks if there is an active session
  Future<Result<bool>> isAuthenticated();

  /// Logs out and deletes the credentials
  Future<Result<void>> logout();

  /// Gets the OAuth client for making API calls
  Future<Result<oauth2.Client?>> getClient();

  /// Gets the PX token from /whoami endpoint for streaming
  Future<Result<String>> getPxToken();
}
