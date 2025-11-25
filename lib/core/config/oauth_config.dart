/// OAuth Configuration for oauth2 package
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

  // Redirect URI debe ser la URL de ngrok
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

  static const int apiTimeoutSeconds = 30;
  static const List<String> scopes = ['openid', 'profile', 'email'];

  // Helper para crear URIs
  static Uri get authorizationEndpointUri => Uri.parse(authorizationEndpoint);
  static Uri get tokenEndpointUri => Uri.parse(tokenEndpoint);
  static Uri get redirectUri => Uri.parse(redirectUrl);
}
