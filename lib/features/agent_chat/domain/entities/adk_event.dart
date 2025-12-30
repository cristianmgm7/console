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
  /// Returns true if this event contains an `adk_request_credential` function call
  /// that requires the user to authenticate with an external service (GitHub, etc.)
  /// to enable MCP tools.
  bool get isAuthenticationRequest {
    // Check function calls in parts
    for (final part in content.parts) {
      if (part.functionCall?.name == 'adk_request_credential') {
        return true;
      }
    }

    // Check actions
    if (actions?.functionCalls != null) {
      return actions!.functionCalls!
          .any((call) => call.name == 'adk_request_credential');
    }

    return false;
  }

  /// Extract authentication request details if present.
  ///
  /// Returns an [AuthenticationRequest] object containing the OAuth2 parameters
  /// needed to authenticate with the requested provider. Returns null if this
  /// event does not contain an authentication request.
  ///
  /// Use this in conjunction with isAuthenticationRequest to handle auth flows.
  AuthenticationRequest? get authenticationRequest {
    // Check parts first
    for (final part in content.parts) {
      if (part.functionCall?.name == 'adk_request_credential') {
        return AuthenticationRequest.fromFunctionCall(part.functionCall!);
      }
    }

    // Check actions
    if (actions?.functionCalls != null) {
      for (final call in actions!.functionCalls!) {
        if (call.name == 'adk_request_credential') {
          return AuthenticationRequest.fromFunctionCall(call);
        }
      }
    }

    return null;
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

    // From actions
    if (actions?.functionCalls != null) {
      calls.addAll(actions!.functionCalls!);
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
    this.functionCalls,
    this.functionResponses,
    this.skipSummarization = false,
  });

  final List<AdkFunctionCall>? functionCalls;
  final List<AdkFunctionResponse>? functionResponses;
  final bool skipSummarization;

  @override
  List<Object?> get props => [functionCalls, functionResponses, skipSummarization];
}

/// Authentication request extracted from adk_request_credential function call.
///
/// Contains all the OAuth2 parameters needed to authenticate with an external
/// service to enable MCP (Model Context Protocol) tools. This is sent by the
/// agent when it needs to use tools that require authentication (GitHub, etc.).
///
/// The authentication flow involves:
/// 1. User opens the [authorizationUrl] in their browser
/// 2. User completes OAuth flow and gets an authorization code
/// 3. Code is exchanged for access/refresh tokens using [tokenUrl]
/// 4. Tokens are sent back to the agent via SendAuthenticationCredentialsUseCase
class AuthenticationRequest extends Equatable {
  const AuthenticationRequest({
    required this.provider,
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.scopes,
    this.additionalParams,
  });

  factory AuthenticationRequest.fromFunctionCall(AdkFunctionCall call) {
    final args = call.args;
    return AuthenticationRequest(
      provider: args['provider'] as String? ?? 'unknown',
      authorizationUrl: args['authorization_url'] as String? ?? args['authorizationUrl'] as String? ?? '',
      tokenUrl: args['token_url'] as String? ?? args['tokenUrl'] as String? ?? '',
      scopes: (args['scopes'] as List<dynamic>?)?.cast<String>() ?? [],
      additionalParams: args['additional_params'] as Map<String, dynamic>? ??
                       args['additionalParams'] as Map<String, dynamic>?,
    );
  }

  final String provider;
  final String authorizationUrl;
  final String tokenUrl;
  final List<String> scopes;
  final Map<String, dynamic>? additionalParams;

  @override
  List<Object?> get props => [
        provider,
        authorizationUrl,
        tokenUrl,
        scopes,
        additionalParams,
      ];
}
