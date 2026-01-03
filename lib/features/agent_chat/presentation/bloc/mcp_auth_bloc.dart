import 'package:carbon_voice_console/core/services/deep_linking_service.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_auth.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/get_authentication_requests_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/send_authentication_credentials_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

@injectable
class McpAuthBloc extends Bloc<McpAuthEvent, McpAuthState> {
  McpAuthBloc(
    this._getAuthRequestsUseCase,
    this._sendCredentialsUseCase,
    this._deepLinkingService,
    this._logger,
  ) : super(const McpAuthInitial()) {
    on<StartAuthListening>(_onStartAuthListening);
    on<AuthRequestDetected>(_onAuthRequestDetected);
    on<AuthCodeProvided>(_onAuthCodeProvided);
    on<AuthCancelled>(_onAuthCancelled);
    on<AuthCodeProvidedFromDeepLink>(_onAuthCodeProvidedFromDeepLink);
    on<StopAuthListening>(_onStopAuthListening);

    // Setup deep link handler for agent OAuth callbacks
    if (!kIsWeb) {
      _deepLinkingService.setDeepLinkHandler(_handleDeepLink);
    }
  }

  final GetAuthenticationRequestsUseCase _getAuthRequestsUseCase;
  final SendAuthenticationCredentialsUseCase _sendCredentialsUseCase;
  final DeepLinkingService _deepLinkingService;
  final Logger _logger;

  // Track pending auth requests by state parameter
  final Map<String, PendingAuthRequest> _pendingAuthRequests = {};

  /// Store a pending auth request when dialog is shown
  void _storePendingAuthRequest(String state, AuthenticationRequest request, String sessionId) {
    _pendingAuthRequests[state] = PendingAuthRequest(
      request: request,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );
  }

  /// Retrieve and remove a pending auth request by state
  PendingAuthRequest? _consumePendingAuthRequest(String state) {
    return _pendingAuthRequests.remove(state);
  }

  /// Clear old pending requests (older than 10 minutes)
  void _clearOldPendingRequests() {
    final now = DateTime.now();
    _pendingAuthRequests.removeWhere((key, value) {
      return now.difference(value.timestamp).inMinutes > 10;
    });
  }

  /// Handle deep link received from the platform
  void _handleDeepLink(String url) {
    _logger.i('🔗 Received deep link: $url');

    try {
      final uri = Uri.parse(url);

      // Check if this is an agent auth callback
      if (uri.scheme == 'carbonvoice' && uri.path == '/agent-auth/callback') {
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final error = uri.queryParameters['error'];

        if (error != null) {
          _logger.e('🔗 OAuth error in deep link: $error');
          // For now, just log the error. The user will see it when they return to the app
          return;
        }

        if (code != null && state != null) {
          _logger.i('🔗 Processing agent OAuth callback with state: $state');
          add(AuthCodeProvidedFromDeepLink(
            authorizationCode: code,
            state: state,
          ));
        } else {
          _logger.e('🔗 Invalid agent OAuth callback - missing code or state');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('🔗 Error processing deep link', error: e, stackTrace: stackTrace);
    }
  }

  /// @deprecated Use AuthRequestDetected instead (avoids duplicate API calls)
  @Deprecated('Use AuthRequestDetected instead')
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

  /// Handle auth requests forwarded from ChatBloc (no duplicate API call!)
  Future<void> _onAuthRequestDetected(
    AuthRequestDetected event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('🔐 Received ${event.requests.length} auth requests from ChatBloc');

    emit(McpAuthListening(sessionId: event.sessionId));

    // Process each auth request
    for (final request in event.requests) {
      _logger.i('🔐 AUTH REQUEST DETECTED for provider: ${request.provider}');
      _logger.i('🔐 Authorization URL: ${request.correctedAuthUri}');

      // Store pending auth request with state for deep link callback
      _storePendingAuthRequest(
        request.state,
        request,
        event.sessionId,
      );

      // Clean up old pending requests
      _clearOldPendingRequests();

      emit(McpAuthRequired(
        request: request,
        sessionId: event.sessionId,
      ));
    }

    // Return to listening state after processing all requests
    emit(McpAuthListening(sessionId: event.sessionId));
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

  /// Handle auth code provided via deep link callback
  Future<void> _onAuthCodeProvidedFromDeepLink(
    AuthCodeProvidedFromDeepLink event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('🔐 Received auth code from deep link with state: ${event.state}');

    // Retrieve the pending auth request
    final pendingRequest = _consumePendingAuthRequest(event.state);

    if (pendingRequest == null) {
      _logger.e('🔐 No pending auth request found for state: ${event.state}');
      emit(McpAuthError(
        message: 'Invalid authentication state. Please try again.',
        sessionId: '', // We don't have session ID without pending request
      ));
      return;
    }

    _logger.i('🔐 Found pending auth request for provider: ${pendingRequest.request.provider}');

    // Process the auth code using the same logic as manual code entry
    final provider = pendingRequest.request.provider ?? 'oauth2';

    emit(McpAuthProcessing(
      provider: provider,
      sessionId: pendingRequest.sessionId,
    ));

    try {
      // Exchange authorization code for credentials
      final credentials = await _completeOAuth2Flow(
        authorizationCode: event.authorizationCode,
        request: pendingRequest.request,
      );

      if (credentials == null) {
        throw Exception('Failed to obtain credentials from OAuth provider');
      }

      // Send credentials back to agent
      final sendResult = await _sendCredentialsUseCase(
        sessionId: pendingRequest.sessionId,
        provider: provider,
        credentials: credentials,
      );

      sendResult.fold(
        onSuccess: (_) {
          emit(McpAuthSuccess(
            provider: provider,
            sessionId: pendingRequest.sessionId,
          ));
        },
        onFailure: (failure) {
          _logger.e('Failed to send authentication credentials', error: failure);
          emit(McpAuthError(
            message: 'Failed to send credentials: ${failure.failure.details ?? failure.failure.code}',
            sessionId: pendingRequest.sessionId,
          ));
        },
      );

      // Return to listening state
      emit(McpAuthListening(sessionId: pendingRequest.sessionId));
    } catch (e, stackTrace) {
      _logger.e('Authentication failed', error: e, stackTrace: stackTrace);

      // Send error to agent
      final errorResult = await _sendCredentialsUseCase.sendError(
        sessionId: pendingRequest.sessionId,
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
        sessionId: pendingRequest.sessionId,
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

/// Represents a pending authentication request waiting for callback
class PendingAuthRequest {
  const PendingAuthRequest({
    required this.request,
    required this.sessionId,
    required this.timestamp,
  });

  final AuthenticationRequest request;
  final String sessionId;
  final DateTime timestamp;
}
