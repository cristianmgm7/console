class AdkConfig {
  static const String baseUrl = String.fromEnvironment(
    'ADK_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String appName = 'src'; // Based on the ADK project structure
  static const int timeoutSeconds = 30;
}
