import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/get_authentication_requests_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/send_authentication_credentials_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

@injectable
class McpAuthBloc extends Bloc<McpAuthEvent, McpAuthState> {
  McpAuthBloc(
    this._getAuthRequestsUseCase,
    this._sendCredentialsUseCase,
    this._logger,
  ) : super(const McpAuthInitial()) {
    on<StartAuthListening>(_onStartAuthListening);
    on<AuthCodeProvided>(_onAuthCodeProvided);
    on<AuthCancelled>(_onAuthCancelled);
    on<StopAuthListening>(_onStopAuthListening);
  }

  final GetAuthenticationRequestsUseCase _getAuthRequestsUseCase;
  final SendAuthenticationCredentialsUseCase _sendCredentialsUseCase;
  final Logger _logger;

  Future<void> _onStartAuthListening(
    StartAuthListening event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('🔐 Checking for auth requests for session: ${event.sessionId}');

    emit(McpAuthListening(sessionId: event.sessionId));

    try {
      final authRequestsResult = await _getAuthRequestsUseCase(
        sessionId: event.sessionId,
        message: event.message,
        context: event.context,
      );

      await authRequestsResult.fold(
        onSuccess: (authRequests) async {
          _logger.i('🔐 Found ${authRequests.length} auth requests');

          // Process each auth request
          for (final authEvent in authRequests) {
            _logger.i('🔐 AUTH REQUEST DETECTED for provider: ${authEvent.request.provider}');
            _logger.i('🔐 Authorization URL: ${authEvent.request.authorizationUrl}');
            
            emit(McpAuthRequired(
              request: authEvent.request,
              sessionId: event.sessionId,
            ));
          }

          // Return to listening state after processing all requests
          emit(McpAuthListening(sessionId: event.sessionId));
        },
        onFailure: (failure) async {
          _logger.e('🔐 Failed to get auth requests', error: failure);
          emit(McpAuthError(
            message: failure.failure.details ?? 'Failed to check for auth requests',
            sessionId: event.sessionId,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('🔐 Failed to check auth requests', error: e, stackTrace: stackTrace);
      emit(McpAuthError(
        message: e.toString(),
        sessionId: event.sessionId,
      ));
    }
  }

  Future<void> _onAuthCodeProvided(
    AuthCodeProvided event,
    Emitter<McpAuthState> emit,
  ) async {
    final provider = event.request.provider ?? 'oauth2';
    
    emit(McpAuthProcessing(
      provider: provider,
      sessionId: event.sessionId,
    ));

    try {
      // Exchange authorization code for credentials
      final credentials = await _completeOAuth2Flow(
        authorizationCode: event.authorizationCode,
        request: event.request,
      );

      if (credentials == null) {
        throw Exception('Failed to obtain credentials from OAuth provider');
      }

      // Send credentials back to agent
      final sendResult = await _sendCredentialsUseCase(
        sessionId: event.sessionId,
        provider: provider,
        credentials: credentials,
      );

      sendResult.fold(
        onSuccess: (_) {
          emit(McpAuthSuccess(
            provider: provider,
            sessionId: event.sessionId,
          ));
        },
        onFailure: (failure) {
          _logger.e('Failed to send authentication credentials', error: failure);
          emit(McpAuthError(
            message: 'Failed to send credentials: ${failure.failure.details ?? failure.failure.code}',
            sessionId: event.sessionId,
          ));
        },
      );

      // Return to listening state
      emit(McpAuthListening(sessionId: event.sessionId));
    } catch (e, stackTrace) {
      _logger.e('Authentication failed', error: e, stackTrace: stackTrace);

      // Send error to agent
      final errorResult = await _sendCredentialsUseCase.sendError(
        sessionId: event.sessionId,
        provider: provider,
        errorMessage: e.toString(),
      );

      errorResult.fold(
        onSuccess: (_) {
          _logger.i('Authentication error sent to agent successfully');
        },
        onFailure: (failure) {
          _logger.e('Failed to send authentication error to agent', error: failure);
        },
      );

      emit(McpAuthError(
        message: e.toString(),
        sessionId: event.sessionId,
      ));
    }
  }

  Future<void> _onAuthCancelled(
    AuthCancelled event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('Authentication cancelled by user');

    final provider = event.request.provider ?? 'oauth2';

    // Send cancellation error to agent
    final cancelResult = await _sendCredentialsUseCase.sendError(
      sessionId: event.sessionId,
      provider: provider,
      errorMessage: 'User cancelled authentication',
    );

    cancelResult.fold(
      onSuccess: (_) {
        _logger.i('Authentication cancellation sent to agent successfully');
      },
      onFailure: (failure) {
        _logger.e('Failed to send authentication cancellation to agent', error: failure);
      },
    );

    emit(McpAuthListening(sessionId: event.sessionId));
  }

  Future<void> _onStopAuthListening(
    StopAuthListening event,
    Emitter<McpAuthState> emit,
  ) async {
    // No need to cancel subscription - emit.forEach handles it automatically
    emit(const McpAuthInitial());
  }

  /// Complete OAuth2 authorization code flow
  Future<oauth2.Credentials?> _completeOAuth2Flow({
    required String authorizationCode,
    required AuthenticationRequest request,
  }) async {
    try {
      final authorizationEndpoint = Uri.parse(request.authorizationUrl ?? '');
      final tokenEndpoint = Uri.parse(request.tokenUrl ?? '');

      final grant = oauth2.AuthorizationCodeGrant(
        request.clientId ?? 'agent-client-id', // Use client ID from request if available
        authorizationEndpoint,
        tokenEndpoint,
        secret: null, // Public client
      );

      // Exchange code for token
      final client = await grant.handleAuthorizationResponse({
        'code': authorizationCode,
      });

      return client.credentials;
    } catch (e, stackTrace) {
      _logger.e('OAuth2 flow failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
