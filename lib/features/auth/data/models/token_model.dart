import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/token.dart';

part 'token_model.g.dart';

@JsonSerializable()
class TokenModel {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'scope')
  final String? scope;

  // For local storage
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  const TokenModel({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
    this.scope,
    this.expiresAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) =>
      _$TokenModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenModelToJson(this);

  Token toDomain() {
    // If we have an explicit expiresAt (from local storage), use it
    // Otherwise calculate from expiresIn
    final expiration = expiresAt ??
        DateTime.now().add(Duration(seconds: expiresIn));

    return Token(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiration,
      tokenType: tokenType,
      scopes: scope?.split(' ') ?? [],
    );
  }

  factory TokenModel.fromDomain(Token token) {
    return TokenModel(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresIn: token.expiresAt.difference(DateTime.now()).inSeconds,
      tokenType: token.tokenType,
      scope: token.scopes.join(' '),
      expiresAt: token.expiresAt,
    );
  }
}
