class OAuthConfig {
  static const String clientId = 'YOUR_CLIENT_ID';
  static const String clientSecret = 'YOUR_CLIENT_SECRET';
  static const String redirectUrl = 'YOUR_REDIRECT_URL';
  static const String authUrl = 'YOUR_AUTH_URL';
  static const String tokenUrl = 'YOUR_TOKEN_URL';
  static const String apiBaseUrl = 'YOUR_API_BASE_URL';
  static const int apiTimeoutSeconds = 30;
  static const List<String> scopes = ['openid', 'profile', 'email'];
}
