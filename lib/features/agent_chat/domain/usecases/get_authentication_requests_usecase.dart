import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for authentication requests.
///
/// This use case processes ADK events and yields only
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

  /// Process events for authentication requests
  Future<Result<List<AuthenticationRequestEvent>>> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      _logger.i('🔐 Getting auth requests for session: $sessionId');

      final eventsResult = await _repository.sendMessage(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      return eventsResult.fold(
        onSuccess: (events) {
          final authRequests = <AuthenticationRequestEvent>[];

          for (final event in events) {
            _logger.d('🔐 Auth usecase checking event from ${event.author}, isAuth=${event.isAuthenticationRequest}');
            
            // Only collect authentication request events
            if (event.isAuthenticationRequest) {
              final authRequest = event.authenticationRequest!;
              _logger.i('🔐 AUTHENTICATION REQUEST FOUND for provider: ${authRequest.provider}');

              authRequests.add(AuthenticationRequestEvent(
                sourceEvent: event,
                request: authRequest,
              ));
            }
          }

          _logger.i('🔐 Found ${authRequests.length} auth requests');
          return success(authRequests);
        },
        onFailure: (failure) {
          _logger.e('🔐 Failed to get events from repository', error: failure);
          // Return empty list on failure - errors will be handled by caller
          return success(<AuthenticationRequestEvent>[]);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('🔐 Error processing auth requests', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
