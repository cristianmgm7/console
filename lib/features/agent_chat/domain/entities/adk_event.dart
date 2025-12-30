import 'package:equatable/equatable.dart';

/// Represents a complete ADK event from the agent execution stream.
///
/// This entity preserves all information from the ADK backend, including:
/// - Text content and function calls/responses
/// - Authentication requests
/// - Status updates and control signals
/// - Multi-part content with text, images, and structured data
///
/// Unlike the old architecture, this entity is NOT filtered - all events
/// are preserved and categorized by use cases at the application layer.
class AdkEvent extends Equatable {
  const AdkEvent({
    required this.id,
    required this.invocationId,
    required this.author,
    required this.timestamp,
    required this.content,
    this.actions,
    this.partial = false,
    this.branch,
    this.longRunningToolIds,
  });

  final String id;
  final String invocationId;
  final String author;
  final DateTime timestamp;
  final AdkContent content;
  final AdkActions? actions;
  final bool partial;
  final String? branch;
  final List<String>? longRunningToolIds;

  @override
  List<Object?> get props => [
        id,
        invocationId,
        author,
        timestamp,
        content,
        actions,
        partial,
        branch,
        longRunningToolIds,
      ];

  /// Check if this is a final user-facing response (text message).
  ///
  /// Returns true if this event contains text content that should be displayed
  /// to the user, and has completed processing (not partial) with no outstanding
  /// function calls.
  bool get isFinalResponse {
    if (partial) return false;
    if (content.parts.isEmpty) return false;

    // Has text and no function calls
    final hasText = content.parts.any((p) => p.text != null);
    final hasFunctionCalls = content.parts.any((p) => p.functionCall != null);

    return hasText && !hasFunctionCalls;
  }

  /// Check if this event contains an authentication request.
  ///
  /// Returns true if this event contains requested auth configs in the actions,
  /// which requires the user to authenticate with an external service (GitHub, etc.)
  /// to enable MCP tools.
  bool get isAuthenticationRequest {
    return actions?.requestedAuthConfigs != null &&
        actions!.requestedAuthConfigs!.isNotEmpty;
  }

  /// Extract authentication request details if present.
  ///
  /// Returns an [AuthenticationRequest] object containing the OAuth2 parameters
  /// needed to authenticate with the requested provider. Returns null if this
  /// event does not contain an authentication request.
  ///
  /// Use this in conjunction with isAuthenticationRequest to handle auth flows.
  AuthenticationRequest? get authenticationRequest {
    if (actions?.requestedAuthConfigs == null ||
        actions!.requestedAuthConfigs!.isEmpty) {
      return null;
    }

    // Get the first auth config from the map
    final authConfig = actions!.requestedAuthConfigs!.values.first;
    return AuthenticationRequest.fromAuthConfig(authConfig);
  }

  /// Get all function calls in this event
  List<AdkFunctionCall> get functionCalls {
    final calls = <AdkFunctionCall>[];

    // From parts
    for (final part in content.parts) {
      if (part.functionCall != null) {
        calls.add(part.functionCall!);
      }
    }

    return calls;
  }

  /// Get text content from this event
  String? get textContent {
    final textParts = content.parts
        .where((p) => p.text != null)
        .map((p) => p.text!)
        .toList();

    if (textParts.isEmpty) return null;
    return textParts.join('\n');
  }
}

/// Content structure matching ADK's Content type
class AdkContent extends Equatable {
  const AdkContent({
    required this.role,
    required this.parts,
  });

  final String role;
  final List<AdkPart> parts;

  @override
  List<Object?> get props => [role, parts];
}

/// Part structure - can contain text, function calls, or function responses
class AdkPart extends Equatable {
  const AdkPart({
    this.text,
    this.functionCall,
    this.functionResponse,
    this.inlineData,
  });

  final String? text;
  final AdkFunctionCall? functionCall;
  final AdkFunctionResponse? functionResponse;
  final AdkInlineData? inlineData;

  @override
  List<Object?> get props => [text, functionCall, functionResponse, inlineData];
}

/// Function call structure
class AdkFunctionCall extends Equatable {
  const AdkFunctionCall({
    required this.name,
    required this.args,
  });

  final String name;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [name, args];
}

/// Function response structure
class AdkFunctionResponse extends Equatable {
  const AdkFunctionResponse({
    required this.name,
    required this.response,
  });

  final String name;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [name, response];
}

/// Inline data (images, etc.)
class AdkInlineData extends Equatable {
  const AdkInlineData({
    required this.mimeType,
    required this.data,
  });

  final String mimeType;
  final String data; // base64 encoded

  @override
  List<Object?> get props => [mimeType, data];
}

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
