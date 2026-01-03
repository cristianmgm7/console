import 'package:equatable/equatable.dart';

/// Actions that can be attached to events
class AdkActions extends Equatable {
  const AdkActions({
    this.stateDelta,
    this.artifactDelta,
    this.transferToAgent,
    this.requestedAuthConfigs,
    this.requestedToolConfirmations,
  });

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;
  final String? transferToAgent;
  final Map<String, RequestedAuthConfig>? requestedAuthConfigs;
  final Map<String, dynamic>? requestedToolConfirmations;

  @override
  List<Object?> get props => [
        stateDelta,
        artifactDelta,
        transferToAgent,
        requestedAuthConfigs,
        requestedToolConfirmations,
      ];
}

/// Requested authentication configuration from the ADK agent.
class RequestedAuthConfig extends Equatable {
  const RequestedAuthConfig({
    this.authScheme,
    this.rawAuthCredential,
    this.exchangedAuthCredential,
    this.credentialKey,
  });

  final AuthScheme? authScheme;
  final AuthCredential? rawAuthCredential;
  final AuthCredential? exchangedAuthCredential;
  final String? credentialKey;

  @override
  List<Object?> get props => [
        authScheme,
        rawAuthCredential,
        exchangedAuthCredential,
        credentialKey,
      ];
}

class AuthScheme extends Equatable {
  const AuthScheme({
    this.type,
    this.flows,
  });

  final String? type;
  final AuthFlows? flows;

  @override
  List<Object?> get props => [type, flows];
}

class AuthFlows extends Equatable {
  const AuthFlows({
    this.authorizationCode,
  });

  final AuthorizationCodeFlow? authorizationCode;

  @override
  List<Object?> get props => [authorizationCode];
}

class AuthorizationCodeFlow extends Equatable {
  const AuthorizationCodeFlow({
    this.authorizationUrl,
    this.tokenUrl,
    this.scopes,
  });

  final String? authorizationUrl;
  final String? tokenUrl;
  final Map<String, String>? scopes;

  @override
  List<Object?> get props => [authorizationUrl, tokenUrl, scopes];
}

class AuthCredential extends Equatable {
  const AuthCredential({
    this.authType,
    this.oauth2,
  });

  final String? authType;
  final OAuth2Data? oauth2;

  @override
  List<Object?> get props => [authType, oauth2];
}

class OAuth2Data extends Equatable {
  const OAuth2Data({
    this.clientId,
    this.clientSecret,
    this.authUri,
    this.state,
  });

  final String? clientId;
  final String? clientSecret;
  final String? authUri;
  final String? state;

  @override
  List<Object?> get props => [clientId, clientSecret, authUri, state];
}

/// Authentication request extracted from requestedAuthConfigs in actions.
///
/// Contains all the OAuth2 parameters needed to authenticate with an external
/// service to enable MCP (Model Context Protocol) tools. This is sent by the
/// agent when it needs to use tools that require authentication (GitHub, etc.).
///
/// The authentication flow involves:
/// 1. User opens the [authUri] in their browser (this already contains all OAuth params)
/// 2. User completes OAuth flow and gets redirected back with a code
/// 3. The backend handles the token exchange
class AuthenticationRequest extends Equatable {
  const AuthenticationRequest({
    required this.authUri,
    required this.state,
    this.provider,
    this.authorizationUrl,
    this.tokenUrl,
    this.scopes,
    this.clientId,
    this.credentialKey,
  });

  factory AuthenticationRequest.fromAuthConfig(RequestedAuthConfig config) {
    // Extract the auth URI from exchangedAuthCredential (this is the complete OAuth URL)
    final authUri = config.exchangedAuthCredential?.oauth2?.authUri ?? '';
    final state = config.exchangedAuthCredential?.oauth2?.state ?? '';

    // Also extract from authScheme for additional info
    final authScheme = config.authScheme;
    final authCode = authScheme?.flows?.authorizationCode;

    return AuthenticationRequest(
      authUri: authUri,
      state: state,
      provider: authScheme?.type,
      authorizationUrl: authCode?.authorizationUrl,
      tokenUrl: authCode?.tokenUrl,
      scopes: authCode?.scopes?.keys.toList(),
      clientId: config.exchangedAuthCredential?.oauth2?.clientId,
      credentialKey: config.credentialKey,
    );
  }

  /// The complete OAuth authorization URI with all parameters already included
  final String authUri;

  /// The state parameter for OAuth flow
  final String state;

  /// Provider type (e.g., "oauth2")
  final String? provider;

  /// Base authorization URL
  final String? authorizationUrl;

  /// Token exchange URL
  final String? tokenUrl;

  /// Requested scopes
  final List<String>? scopes;

  /// OAuth client ID
  final String? clientId;

  /// Credential key for the agent
  final String? credentialKey;

  /// Get the corrected OAuth URI with proper parameters for Carbon Voice
  ///
  /// Fixes:
  /// - Changes `prompt=consent` to `prompt=login` (Carbon Voice requirement)
  /// - Ensures redirect_uri is included
  String get correctedAuthUri {
    if (authUri.isEmpty) return authUri;

    try {
      final uri = Uri.parse(authUri);
      final params = Map<String, String>.from(uri.queryParameters);

      // Fix prompt parameter for Carbon Voice
      if (params.containsKey('prompt') && params['prompt'] == 'consent') {
        params['prompt'] = 'login';
      }

      // Build corrected URI
      return uri.replace(queryParameters: params).toString();
    } on FormatException {
      // If parsing fails, return original
      return authUri;
    }
  }

  @override
  List<Object?> get props => [
        authUri,
        state,
        provider,
        authorizationUrl,
        tokenUrl,
        scopes,
        clientId,
        credentialKey,
      ];
}
