import 'package:json_annotation/json_annotation.dart';

part 'mcp_auth_dto.g.dart';

/// DTO for ADK request credential function call
@JsonSerializable()
class AdkRequestCredentialDto {
  AdkRequestCredentialDto({
    required this.authConfig,
  });

  factory AdkRequestCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$AdkRequestCredentialDtoFromJson(json);

  final AuthConfigDto authConfig;

  Map<String, dynamic> toJson() => _$AdkRequestCredentialDtoToJson(this);
}

/// DTO for auth configuration from ADK
@JsonSerializable()
class AuthConfigDto {
  AuthConfigDto({
    required this.exchangedAuthCredential,
  });

  factory AuthConfigDto.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigDtoFromJson(json);

  final ExchangedAuthCredentialDto exchangedAuthCredential;

  Map<String, dynamic> toJson() => _$AuthConfigDtoToJson(this);
}

/// DTO for exchanged auth credential
@JsonSerializable()
class ExchangedAuthCredentialDto {
  ExchangedAuthCredentialDto({
    required this.oauth2,
  });

  factory ExchangedAuthCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$ExchangedAuthCredentialDtoFromJson(json);

  final OAuth2ConfigDto oauth2;

  Map<String, dynamic> toJson() => _$ExchangedAuthCredentialDtoToJson(this);
}

/// DTO for OAuth2 configuration from ADK
@JsonSerializable()
class OAuth2ConfigDto {
  OAuth2ConfigDto({
    required this.authUri,
    required this.tokenUri,
    required this.clientId,
    required this.clientSecret,
    this.scopes,
    this.authResponseUri,
    this.redirectUri,
  });

  factory OAuth2ConfigDto.fromJson(Map<String, dynamic> json) =>
      _$OAuth2ConfigDtoFromJson(json);

  @JsonKey(name: 'auth_uri')
  final String authUri;

  @JsonKey(name: 'token_uri')
  final String tokenUri;

  @JsonKey(name: 'client_id')
  final String clientId;

  @JsonKey(name: 'client_secret')
  final String clientSecret;

  final List<String>? scopes;

  @JsonKey(name: 'auth_response_uri')
  String? authResponseUri;

  @JsonKey(name: 'redirect_uri')
  String? redirectUri;

  Map<String, dynamic> toJson() => _$OAuth2ConfigDtoToJson(this);
}
