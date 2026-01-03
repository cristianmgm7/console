import 'package:carbon_voice_console/core/api/generated/lib/api.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_actions.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_content.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

extension EventToDomain on Event {

  /// Convert generated Event to domain AdkEvent
  ///
  /// Convert generated Event to domain AdkEvent
  ///
  /// This preserves ALL event information and normalizes it into the domain model.
  AdkEvent toAdkEvent() {
    // 1. Convert standard content parts
    final parts = content.parts.map((p) => p.toAdkPart()).toList();

    return AdkEvent(
      id: id ?? '',
      invocationId: invocationId ?? '',
      author: author,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
          : DateTime.now(),
      // Create simplified content with all parts merged
      content: AdkContent(
        role: content.role?.value ?? '',
        parts: parts,
      ),
      actions: actions?.toAdkActions(),
      partial: partial ?? false,
      branch: branch,
      longRunningToolIds: longRunningToolIds,
    );
  }
}

extension ContentToDomain on Content {
  // No longer used directly, logic moved to toAdkEvent to allow merging
}

extension ContentPartsInnerToDomain on ContentPartsInner {
  AdkPart toAdkPart() {
    if (text != null) {
      return AdkTextPart(
        text: text!,
      );
    } else if (inlineData != null) {
      return AdkInlineDataPart(
        mimeType: inlineData!.mimeType ?? '',
        data: inlineData!.data ?? '',
      );
    } else if (functionCall != null) {
      return AdkFunctionCallPart(
        id: 'unknown', // ID is not in the DTO part structure
        name: functionCall!.name ?? '',
        args: functionCall!.args,
      );
    } else if (functionResponse != null) {
      return AdkFunctionResponsePart(
        name: functionResponse!.name ?? '',
        response: functionResponse!.response,
      );
    } else {
      return const AdkUnknownPart();
    }
  }
}

extension EventActionsFunctionCallsInnerToDomain on EventActionsFunctionCallsInner {
  AdkFunctionCallPart toAdkFunctionCallPart() {
    return AdkFunctionCallPart(
      name: name ?? '',
      args: args.cast<String, dynamic>(),
      // The OpenAPI DTO might not have ID, but we map what we have
      id: null, 
    );
  }
}

extension EventActionsFunctionResponsesInnerToDomain on EventActionsFunctionResponsesInner {
  AdkFunctionResponsePart toAdkFunctionResponsePart() {
    return AdkFunctionResponsePart(
      name: name ?? '',
      response: response.cast<String, dynamic>(),
    );
  }
}

extension ContentPartsInnerOneOf1InlineDataToDomain on ContentPartsInnerOneOf1InlineData {
   // Logic inlined into ContentPartsInnerToDomain
}

/// Utility function to parse Event with extended actions from JSON
Event? parseEventWithExtendedActions(dynamic value) {
  if (value is Map) {
    final json = value.cast<String, dynamic>();

    return Event(
      author: mapValueOfType<String>(json, 'author')!,
      content: Content.fromJson(json['content'])!,
      invocationId: mapValueOfType<String>(json, 'invocationId'),
      actions: json['actions'] != null ? ExtendedEventActions.fromJson(json['actions']) : null,
      longRunningToolIds: json['longRunningToolIds'] is Iterable
          ? (json['longRunningToolIds'] as Iterable).cast<String>().toList(growable: false)
          : const [],
      branch: mapValueOfType<String>(json, 'branch'),
      id: mapValueOfType<String>(json, 'id'),
      timestamp: num.parse('${json['timestamp']}'),
      partial: mapValueOfType<bool>(json, 'partial'),
    );
  }
  return null;
}

// Extended EventActions with authentication fields not in OpenAPI spec
class ExtendedEventActions extends EventActions {
  ExtendedEventActions({
    super.functionCalls,
    super.functionResponses,
    super.skipSummarization,
    this.stateDelta,
    this.artifactDelta,
    this.transferToAgent,
    this.requestedAuthConfigs,
    this.requestedToolConfirmations,
  });

  factory ExtendedEventActions.fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();
      return ExtendedEventActions(
        functionCalls: EventActionsFunctionCallsInner.listFromJson(json['functionCalls']),
        functionResponses: EventActionsFunctionResponsesInner.listFromJson(json['functionResponses']),
        skipSummarization: mapValueOfType<bool>(json, 'skipSummarization'),
        stateDelta: mapValueOfType<Map<String, dynamic>>(json, 'stateDelta'),
        artifactDelta: mapValueOfType<Map<String, dynamic>>(json, 'artifactDelta'),
        transferToAgent: mapValueOfType<String>(json, 'transferToAgent'),
        requestedAuthConfigs: json['requestedAuthConfigs'] != null
            ? (json['requestedAuthConfigs'] as Map<String, dynamic>).map(
                (key, authConfigValue) {
                  final configJson = authConfigValue as Map<String, dynamic>;
                  return MapEntry(key, RequestedAuthConfig(
                    authScheme: configJson['authScheme'] != null ? (() {
                      final authSchemeJson = configJson['authScheme'] as Map<String, dynamic>;
                      return AuthScheme(
                        type: authSchemeJson['type'] as String?,
                        flows: authSchemeJson['flows'] != null ? (() {
                          final flowsJson = authSchemeJson['flows'] as Map<String, dynamic>;
                          return AuthFlows(
                            authorizationCode: flowsJson['authorizationCode'] != null ? (() {
                              final authCodeJson = flowsJson['authorizationCode'] as Map<String, dynamic>;
                              return AuthorizationCodeFlow(
                                authorizationUrl: authCodeJson['authorizationUrl'] as String?,
                                tokenUrl: authCodeJson['tokenUrl'] as String?,
                                scopes: (authCodeJson['scopes'] as Map<String, dynamic>?)?.cast<String, String>(),
                              );
                            })() : null,
                          );
                        })() : null,
                      );
                    })() : null,
                    rawAuthCredential: configJson['rawAuthCredential'] != null ? (() {
                      final rawCredentialJson = configJson['rawAuthCredential'] as Map<String, dynamic>;
                      return AuthCredential(
                        authType: rawCredentialJson['authType'] as String?,
                        oauth2: rawCredentialJson['oauth2'] != null ? (() {
                          final oauth2Json = rawCredentialJson['oauth2'] as Map<String, dynamic>;
                          return OAuth2Data(
                            clientId: oauth2Json['clientId'] as String?,
                            clientSecret: oauth2Json['clientSecret'] as String?,
                            authUri: oauth2Json['authUri'] as String?,
                            state: oauth2Json['state'] as String?,
                          );
                        })() : null,
                      );
                    })() : null,
                    exchangedAuthCredential: configJson['exchangedAuthCredential'] != null ? (() {
                      final exchangedCredentialJson = configJson['exchangedAuthCredential'] as Map<String, dynamic>;
                      return AuthCredential(
                        authType: exchangedCredentialJson['authType'] as String?,
                        oauth2: exchangedCredentialJson['oauth2'] != null ? (() {
                          final oauth2Json = exchangedCredentialJson['oauth2'] as Map<String, dynamic>;
                          return OAuth2Data(
                            clientId: oauth2Json['clientId'] as String?,
                            clientSecret: oauth2Json['clientSecret'] as String?,
                            authUri: oauth2Json['authUri'] as String?,
                            state: oauth2Json['state'] as String?,
                          );
                        })() : null,
                      );
                    })() : null,
                    credentialKey: configJson['credentialKey'] as String?,
                  ));
                },
              )
            : null,
        requestedToolConfirmations: mapValueOfType<Map<String, dynamic>>(json, 'requestedToolConfirmations'),
      );
    }
    return ExtendedEventActions();
  }

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;
  final String? transferToAgent;
  final Map<String, RequestedAuthConfig>? requestedAuthConfigs;
  final Map<String, dynamic>? requestedToolConfirmations;
}

extension EventActionsToDomain on EventActions {
  AdkActions toAdkActions() {
    // If this is already an ExtendedEventActions, use the extended fields
    if (this is ExtendedEventActions) {
      final extended = this as ExtendedEventActions;
      return AdkActions(
        stateDelta: extended.stateDelta,
        artifactDelta: extended.artifactDelta,
        transferToAgent: extended.transferToAgent,
        requestedAuthConfigs: extended.requestedAuthConfigs,
        requestedToolConfirmations: extended.requestedToolConfirmations,
      );
    }

    // For regular EventActions (from OpenAPI spec), return empty actions
    return const AdkActions(  
    );
  }
}
