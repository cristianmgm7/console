class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Route paths
  static const String login = '/login';
  static const String oauthCallback = '/auth/callback';
  static const String dashboard = '/dashboard';
  static const String users = '/dashboard/users';
  static const String voiceMemos = '/dashboard/voice-memos';
  static const String agentChat = '/dashboard/agent-chat';
  static const String settings = '/dashboard/settings';

  // Preview routes
  static const String previewComposer = '/dashboard/preview/composer';
  static const String previewConfirmation = '/dashboard/preview/confirmation';
}
