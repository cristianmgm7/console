import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
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
  Future<Result<void>> call({
    required String sessionId,
    required String provider,
    required oauth2.Credentials credentials,
  }) async {
    try {
      _logger.i('Sending auth credentials for provider: $provider');

      final result = await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        expiresAt: credentials.expiration,
      );

      return result.fold(
        onSuccess: (_) {
          _logger.i('Credentials sent successfully');
          return success(null);
        },
        onFailure: (failure) {
          _logger.e('Failed to send credentials', error: failure);
          return failure;
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Unexpected error sending credentials', error: e, stackTrace: stackTrace);
      return failure(UnknownFailure(details: 'Failed to send credentials: $e'));
    }
  }

  /// Send authentication error back to agent
  Future<Result<void>> sendError({
    required String sessionId,
    required String provider,
    required String errorMessage,
  }) async {
    try {
      _logger.w('Sending authentication error: $errorMessage');

      // Send error as credentials with ERROR token
      final result = await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: 'ERROR',
        refreshToken: errorMessage,
      );

      return result.fold(
        onSuccess: (_) {
          _logger.i('Authentication error sent successfully');
          return success(null);
        },
        onFailure: (failure) {
          _logger.e('Failed to send authentication error', error: failure);
          return failure;
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Unexpected error sending authentication error', error: e, stackTrace: stackTrace);
      return failure(UnknownFailure(details: 'Failed to send auth error: $e'));
    }
  }
}
