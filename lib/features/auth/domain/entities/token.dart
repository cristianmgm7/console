import 'package:equatable/equatable.dart';

class Token extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final List<String> scopes;

  const Token({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
    this.scopes = const [],
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  bool get canRefresh => refreshToken != null;

  String get authorizationHeader => '$tokenType $accessToken';

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresAt,
        tokenType,
        scopes,
      ];
}
