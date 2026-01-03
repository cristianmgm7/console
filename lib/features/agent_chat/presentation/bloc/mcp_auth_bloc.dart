import 'package:carbon_voice_console/core/services/deep_linking_service.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_auth.dart';
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
    this._sendCredentialsUseCase,
    this._deepLinkingService,
    this._logger,
  ) : super(const McpAuthInitial()) {
    on<AuthRequestDetected>(_onAuthRequestDetected);
    on<AuthCodeProvided>(_onAuthCodeProvided);
    on<AuthCancelled>(_onAuthCancelled);
    on<AuthCodeProvidedFromDeepLink>(_onAuthCodeProvidedFromDeepLink);
    on<AuthErrorFromDeepLink>(_onAuthErrorFromDeepLink);
    on<StopAuthListening>(_onStopAuthListening);

    // Setup deep link handler for agent OAuth callbacks
    // Use the same path as main login - we'll detect if it's agent auth by checking pending requests
    if (!kIsWeb) {
      _deepLinkingService.setDeepLinkHandlerForPath('/auth/callback', _handleDeepLink);
    }
  }

  final SendAuthenticationCredentialsUseCase _sendCredentialsUseCase;
  final DeepLinkingService _deepLinkingService;
  final Logger _logger;

  // Track pending auth requests by state parameter
  final Map<String, PendingAuthRequest> _pendingAuthRequests = {};

  /// Store a pending auth request when dialog is shown
  void _storePendingAuthRequest(String state, AuthenticationRequest request, String sessionId) {
    _logger.i('🔐 Storing pending auth request - state: $state, sessionId: $sessionId, provider: ${request.provider}');
    _pendingAuthRequests[state] = PendingAuthRequest(
      request: request,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );
    _logger.i('🔐 Total pending requests: ${_pendingAuthRequests.length}');
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
  /// This shares the same path (/auth/callback) as main login, so we need to check
  /// if this is an agent auth request by checking if the state is in our pending requests
  void _handleDeepLink(String url) {
    _logger.i('🔗 Received auth deep link (checking if agent auth): $url');

    try {
      final uri = Uri.parse(url);

      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      // Check if this is an agent auth request by looking for the state in pending requests
      // If state is not found, this is likely a user login - let AuthBloc handle it
      if (state != null && !_pendingAuthRequests.containsKey(state)) {
        _logger.i('🔗 State $state not found in pending agent auth requests - likely user login, ignoring');
        return; // Let AuthBloc handle it
      }

      _logger.i('🔗 This is an agent auth request - processing');

      if (error != null) {
        _logger.e('🔗 OAuth error in deep link: $error - $errorDescription');
        
        // Try to find the sessionId from pending requests
        // If we have a state, use it; otherwise use the most recent pending request
        String? sessionId;
        if (state != null) {
          final pendingRequest = _pendingAuthRequests[state];
          sessionId = pendingRequest?.sessionId;
          _pendingAuthRequests.remove(state);
        } else if (_pendingAuthRequests.isNotEmpty) {
          // Use the most recent pending request
          final mostRecent = _pendingAuthRequests.values.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
          );
          sessionId = mostRecent.sessionId;
          // Clear all pending requests since we don't know which one failed
          _pendingAuthRequests.clear();
        }

        // Emit error state so dialog can close
        add(AuthErrorFromDeepLink(
          error: error,
          errorDescription: errorDescription ?? 'OAuth authentication failed',
          sessionId: sessionId ?? '',
        ));
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
        
        // Try to find sessionId from pending requests
        String? sessionId;
        if (state != null) {
          final pendingRequest = _pendingAuthRequests[state];
          sessionId = pendingRequest?.sessionId;
        } else if (_pendingAuthRequests.isNotEmpty) {
          final mostRecent = _pendingAuthRequests.values.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
          );
          sessionId = mostRecent.sessionId;
        }

        // Emit error state so dialog can close
        add(AuthErrorFromDeepLink(
          error: 'INVALID_CALLBACK',
          errorDescription: 'Invalid OAuth callback - missing code or state parameter',
          sessionId: sessionId ?? '',
        ));
      }
    } on Exception catch (e, stackTrace) {
      _logger.e('🔗 Error processing agent auth deep link', error: e, stackTrace: stackTrace);
      
      // Try to find sessionId from most recent pending request
      String? sessionId;
      if (_pendingAuthRequests.isNotEmpty) {
        final mostRecent = _pendingAuthRequests.values.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        sessionId = mostRecent.sessionId;
      }

      // Emit error state so dialog can close
      add(AuthErrorFromDeepLink(
        error: 'PROCESSING_ERROR',
        errorDescription: 'Error processing deep link: ${e.toString()}',
        sessionId: sessionId ?? '',
      ));
    }
  }

  

  /// Handle auth requests forwarded from ChatBloc (no duplicate API call!)
  Future<void> _onAuthRequestDetected(
    AuthRequestDetected event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('🔐 Received ${event.requests.length} auth requests from ChatBloc');

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
    } on Exception catch (e, stackTrace) {
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
    _logger.i('🔐 Pending auth requests: ${_pendingAuthRequests.keys.toList()}');

    // Retrieve the pending auth request
    final pendingRequest = _consumePendingAuthRequest(event.state);

    if (pendingRequest == null) {
      _logger.e('🔐 No pending auth request found for state: ${event.state}');
      _logger.e('🔐 Available states: ${_pendingAuthRequests.keys.toList()}');
      emit(const McpAuthError(
        message: 'Invalid authentication state. Please try again.',
        sessionId: '', // We don't have session ID without pending request
      ));
      return;
    }

    _logger.i('🔐 Found pending auth request for provider: ${pendingRequest.request.provider}, sessionId: ${pendingRequest.sessionId}');

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
    } on Exception catch (e, stackTrace) {
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

  /// Handle OAuth error received via deep link callback
  Future<void> _onAuthErrorFromDeepLink(
    AuthErrorFromDeepLink event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.e('🔗 OAuth error from deep link: ${event.error} - ${event.errorDescription}');

    final provider = 'oauth2'; // Default provider

    // Send error to agent if we have a sessionId
    if (event.sessionId.isNotEmpty) {
      final errorResult = await _sendCredentialsUseCase.sendError(
        sessionId: event.sessionId,
        provider: provider,
        errorMessage: '${event.error}: ${event.errorDescription}',
      );

      errorResult.fold(
        onSuccess: (_) {
          _logger.i('Authentication error sent to agent successfully');
        },
        onFailure: (failure) {
          _logger.e('Failed to send authentication error to agent', error: failure);
        },
      );
    }

    // Emit error state so dialog can close
    emit(McpAuthError(
      message: event.errorDescription,
      sessionId: event.sessionId,
    ));
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

    emit(const McpAuthInitial());
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
      );

      // Exchange code for token
      final client = await grant.handleAuthorizationResponse({
        'code': authorizationCode,
      });

      return client.credentials;
    } on Exception catch (e, stackTrace) {
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
