/// OAuth Configuration
/// Values are loaded from --dart-define at build time
/// Never hardcode secrets here!
class OAuthConfig {
  static const String clientId = String.fromEnvironment(
    'OAUTH_CLIENT_ID',
    defaultValue: 'YOUR_CLIENT_ID',
  );
  
  static const String clientSecret = String.fromEnvironment(
    'OAUTH_CLIENT_SECRET',
    defaultValue: 'YOUR_CLIENT_SECRET',
  );
  
  static const String redirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'YOUR_REDIRECT_URL',
  );
  
  static const String authUrl = String.fromEnvironment(
    'OAUTH_AUTH_URL',
    defaultValue: 'YOUR_AUTH_URL',
  );
  
  static const String tokenUrl = String.fromEnvironment(
    'OAUTH_TOKEN_URL',
    defaultValue: 'YOUR_TOKEN_URL',
  );
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'YOUR_API_BASE_URL',
  );
  
  static const int apiTimeoutSeconds = 30;
  static const List<String> scopes = ['openid', 'profile', 'email'];
}
