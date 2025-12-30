import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for authentication requests.
///
/// This use case processes the raw ADK event stream and yields only
/// [AuthenticationRequestEvent] when the agent sends an `adk_request_credential`
/// function call requesting MCP tool authentication.
///
/// Used by McpAuthBloc to detect when authentication dialogs should be shown.
/// Other event types are ignored - this use case has a single, focused responsibility.
@injectable
class GetAuthenticationRequestsUseCase {
  const GetAuthenticationRequestsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process event stream for authentication requests
  Stream<AuthenticationRequestEvent> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.i('🔐 Starting auth request stream for session: $sessionId');

      final eventStream = _repository.sendMessageStreaming(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      await for (final event in eventStream) {
        _logger.d('🔐 Auth usecase received event from ${event.author}, isAuth=${event.isAuthenticationRequest}');
        
        // Only yield authentication request events
        if (event.isAuthenticationRequest) {
          final authRequest = event.authenticationRequest!;
          _logger.i('🔐 AUTHENTICATION REQUEST FOUND for provider: ${authRequest.provider}');

          yield AuthenticationRequestEvent(
            sourceEvent: event,
            request: authRequest,
          );
        }
      }

      _logger.i('🔐 Auth request stream completed for session: $sessionId');
    } catch (e, stackTrace) {
      _logger.e('🔐 Error in auth request stream', error: e, stackTrace: stackTrace);
      // Don't yield errors here - let them propagate to chat use case
      rethrow;
    }
  }
}
