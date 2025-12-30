import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

/// Use case to send authentication credentials back to the ADK agent.
///
/// This use case handles the final step of the MCP authentication flow.
/// After the user completes OAuth2 authentication and receives credentials,
/// this use case formats and sends them back to the ADK agent as a function response.
///
/// The agent can then use the authenticated credentials to access MCP tools
/// (GitHub API, etc.) on behalf of the user.
///
/// Also provides an [sendError] method for cases where authentication fails
/// or is cancelled by the user.
@injectable
class SendAuthenticationCredentialsUseCase {
  const SendAuthenticationCredentialsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Send credentials obtained from OAuth flow back to agent
  Future<void> call({
    required String sessionId,
    required String provider,
    required oauth2.Credentials credentials,
  }) async {
    try {
      _logger.i('Sending auth credentials for provider: $provider');

      await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        expiresAt: credentials.expiration,
      );

      _logger.i('Credentials sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send credentials', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Send authentication error back to agent
  Future<void> sendError({
    required String sessionId,
    required String provider,
    required String errorMessage,
  }) async {
    try {
      _logger.w('Sending authentication error: $errorMessage');

      // Send error as credentials with ERROR token
      await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: 'ERROR',
        refreshToken: errorMessage,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to send auth error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
