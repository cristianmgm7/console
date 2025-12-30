import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

extension EventDtoToDomain on EventDto {
  /// Convert EventDto to domain AdkEvent
  ///
  /// Unlike the old mapper, this preserves ALL event information
  AdkEvent toAdkEvent() {
    return AdkEvent(
      id: id ?? '',
      invocationId: invocationId ?? '',
      author: author,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
          : DateTime.now(),
      content: content.toAdkContent(),
      actions: actions?.toAdkActions(),
      partial: partial ?? false,
      branch: branch,
      longRunningToolIds: longRunningToolIds,
    );
  }
}

extension ContentDtoToDomain on ContentDto {
  AdkContent toAdkContent() {
    return AdkContent(
      role: role,
      parts: parts.map((p) => p.toAdkPart()).toList(),
    );
  }
}

extension PartDtoToDomain on PartDto {
  AdkPart toAdkPart() {
    return AdkPart(
      text: text,
      functionCall: functionCall?.toAdkFunctionCall(),
      functionResponse: functionResponse?.toAdkFunctionResponse(),
      inlineData: inlineData?.toAdkInlineData(),
    );
  }
}

extension FunctionCallDtoToDomain on FunctionCallDto {
  AdkFunctionCall toAdkFunctionCall() {
    return AdkFunctionCall(
      name: name,
      args: args,
    );
  }
}

extension FunctionResponseDtoToDomain on FunctionResponseDto {
  AdkFunctionResponse toAdkFunctionResponse() {
    return AdkFunctionResponse(
      name: name,
      response: response,
    );
  }
}

extension InlineDataDtoToDomain on InlineDataDto {
  AdkInlineData toAdkInlineData() {
    return AdkInlineData(
      mimeType: mimeType,
      data: data,
    );
  }
}

extension ActionsDtoToDomain on ActionsDto {
  AdkActions toAdkActions() {
    return AdkActions(
      stateDelta: stateDelta,
      artifactDelta: artifactDelta,
      transferToAgent: transferToAgent,
      requestedAuthConfigs: requestedAuthConfigs?.map(
        (key, value) => MapEntry(key, value.toRequestedAuthConfig()),
      ),
      requestedToolConfirmations: requestedToolConfirmations,
    );
  }
}

extension RequestedAuthConfigDtoToDomain on RequestedAuthConfigDto {
  RequestedAuthConfig toRequestedAuthConfig() {
    return RequestedAuthConfig(
      authScheme: authScheme?.toAuthScheme(),
      rawAuthCredential: rawAuthCredential?.toAuthCredential(),
      exchangedAuthCredential: exchangedAuthCredential?.toAuthCredential(),
      credentialKey: credentialKey,
    );
  }
}

extension AuthSchemeDtoToDomain on AuthSchemeDto {
  AuthScheme toAuthScheme() {
    return AuthScheme(
      type: type,
      flows: flows?.toAuthFlows(),
    );
  }
}

extension AuthFlowsDtoToDomain on AuthFlowsDto {
  AuthFlows toAuthFlows() {
    return AuthFlows(
      authorizationCode: authorizationCode?.toAuthorizationCodeFlow(),
    );
  }
}

extension AuthorizationCodeFlowDtoToDomain on AuthorizationCodeFlowDto {
  AuthorizationCodeFlow toAuthorizationCodeFlow() {
    return AuthorizationCodeFlow(
      authorizationUrl: authorizationUrl,
      tokenUrl: tokenUrl,
      scopes: scopes,
    );
  }
}

extension AuthCredentialDtoToDomain on AuthCredentialDto {
  AuthCredential toAuthCredential() {
    return AuthCredential(
      authType: authType,
      oauth2: oauth2?.toOAuth2Data(),
    );
  }
}

extension OAuth2DataDtoToDomain on OAuth2DataDto {
  OAuth2Data toOAuth2Data() {
    return OAuth2Data(
      clientId: clientId,
      clientSecret: clientSecret,
      authUri: authUri,
      state: state,
    );
  }
}
