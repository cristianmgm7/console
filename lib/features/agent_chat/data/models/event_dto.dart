import 'package:json_annotation/json_annotation.dart';

part 'event_dto.g.dart';

@JsonSerializable()
class EventDto {

  EventDto({
    required this.author, 
    required this.content, 
    this.id,
    this.invocationId,
    this.timestamp,
    this.actions,
    this.longRunningToolIds,
    this.branch,
    this.partial,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  final String? id;
  final String? invocationId;
  final String author;
  final double? timestamp;
  final ContentDto content;
  final ActionsDto? actions;
  final List<String>? longRunningToolIds;
  final String? branch;
  final bool? partial;

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
}

@JsonSerializable()
class ContentDto {

  ContentDto({
    required this.role,
    required this.parts,
  });

  factory ContentDto.fromJson(Map<String, dynamic> json) =>
      _$ContentDtoFromJson(json);
      
  final String role;
  final List<PartDto> parts;

  Map<String, dynamic> toJson() => _$ContentDtoToJson(this);
}

@JsonSerializable()
class PartDto {

  PartDto({
    this.text,
    this.inlineData,
    this.functionCall,
    this.functionResponse,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) =>
      _$PartDtoFromJson(json);
  final String? text;
  final InlineDataDto? inlineData;
  final FunctionCallDto? functionCall;
  final FunctionResponseDto? functionResponse;

  Map<String, dynamic> toJson() => _$PartDtoToJson(this);
}

@JsonSerializable()
class InlineDataDto {
  InlineDataDto({
    required this.mimeType,
    required this.data,
  });

  factory InlineDataDto.fromJson(Map<String, dynamic> json) =>
      _$InlineDataDtoFromJson(json);

  final String mimeType;
  final String data;

  Map<String, dynamic> toJson() => _$InlineDataDtoToJson(this);
}

@JsonSerializable()
class FunctionCallDto {

  FunctionCallDto({
    required this.name,
    required this.args,
  });

  factory FunctionCallDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallDtoFromJson(json);
  final String name;
  final Map<String, dynamic> args;

  Map<String, dynamic> toJson() => _$FunctionCallDtoToJson(this);
}

@JsonSerializable()
class FunctionResponseDto {

  FunctionResponseDto({
    required this.name,
    required this.response,
  });

  factory FunctionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseDtoFromJson(json);
  final String name;
  final Map<String, dynamic> response;

  Map<String, dynamic> toJson() => _$FunctionResponseDtoToJson(this);
}

@JsonSerializable()
class ActionsDto {

  ActionsDto({
    this.stateDelta,
    this.artifactDelta,
    this.transferToAgent,
    this.requestedAuthConfigs,
    this.requestedToolConfirmations,
  });

  factory ActionsDto.fromJson(Map<String, dynamic> json) =>
      _$ActionsDtoFromJson(json);

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;
  final String? transferToAgent;
  final Map<String, RequestedAuthConfigDto>? requestedAuthConfigs;
  final Map<String, dynamic>? requestedToolConfirmations;

  Map<String, dynamic> toJson() => _$ActionsDtoToJson(this);
}

@JsonSerializable()
class RequestedAuthConfigDto {

  RequestedAuthConfigDto({
    this.authScheme,
    this.rawAuthCredential,
    this.exchangedAuthCredential,
    this.credentialKey,
  });

  factory RequestedAuthConfigDto.fromJson(Map<String, dynamic> json) =>
      _$RequestedAuthConfigDtoFromJson(json);

  final AuthSchemeDto? authScheme;
  final AuthCredentialDto? rawAuthCredential;
  final AuthCredentialDto? exchangedAuthCredential;
  final String? credentialKey;

  Map<String, dynamic> toJson() => _$RequestedAuthConfigDtoToJson(this);
}

@JsonSerializable()
class AuthSchemeDto {

  AuthSchemeDto({
    this.type,
    this.flows,
  });

  factory AuthSchemeDto.fromJson(Map<String, dynamic> json) =>
      _$AuthSchemeDtoFromJson(json);

  final String? type;
  final AuthFlowsDto? flows;

  Map<String, dynamic> toJson() => _$AuthSchemeDtoToJson(this);
}

@JsonSerializable()
class AuthFlowsDto {

  AuthFlowsDto({
    this.authorizationCode,
  });

  factory AuthFlowsDto.fromJson(Map<String, dynamic> json) =>
      _$AuthFlowsDtoFromJson(json);

  final AuthorizationCodeFlowDto? authorizationCode;

  Map<String, dynamic> toJson() => _$AuthFlowsDtoToJson(this);
}

@JsonSerializable()
class AuthorizationCodeFlowDto {

  AuthorizationCodeFlowDto({
    this.authorizationUrl,
    this.tokenUrl,
    this.scopes,
  });

  factory AuthorizationCodeFlowDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorizationCodeFlowDtoFromJson(json);

  final String? authorizationUrl;
  final String? tokenUrl;
  final Map<String, String>? scopes;

  Map<String, dynamic> toJson() => _$AuthorizationCodeFlowDtoToJson(this);
}

@JsonSerializable()
class AuthCredentialDto {

  AuthCredentialDto({
    this.authType,
    this.oauth2,
  });

  factory AuthCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialDtoFromJson(json);

  final String? authType;
  final OAuth2DataDto? oauth2;

  Map<String, dynamic> toJson() => _$AuthCredentialDtoToJson(this);
}

@JsonSerializable()
class OAuth2DataDto {

  OAuth2DataDto({
    this.clientId,
    this.clientSecret,
    this.authUri,
    this.state,
  });

  factory OAuth2DataDto.fromJson(Map<String, dynamic> json) =>
      _$OAuth2DataDtoFromJson(json);

  final String? clientId;
  final String? clientSecret;
  final String? authUri;
  final String? state;

  Map<String, dynamic> toJson() => _$OAuth2DataDtoToJson(this);
}
