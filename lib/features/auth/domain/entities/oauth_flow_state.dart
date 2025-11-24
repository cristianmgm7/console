import 'package:equatable/equatable.dart';

class OAuthFlowState extends Equatable {
  final String codeVerifier;
  final String state;

  const OAuthFlowState({
    required this.codeVerifier,
    required this.state,
  });

  @override
  List<Object?> get props => [codeVerifier, state];
}
