import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

@LazySingleton()
class ExchangeCodeUseCase {
  final AuthRepository _repository;

  const ExchangeCodeUseCase(this._repository);

  Future<Result<Token>> call({
    required String code,
    required String state,
  }) async {
    // Validate state parameter (CSRF protection)
    final flowStateResult = await _repository.getCurrentFlowState();

    return flowStateResult.fold(
      onSuccess: (flowState) async {
        if (flowState == null) {
          return failure<Token>(const AuthFailure(
            code: 'NO_FLOW',
            details: 'No OAuth flow in progress',
          ));
        }

        if (flowState.state != state) {
          return failure<Token>(const InvalidStateFailure());
        }

        // Exchange code for token
        final tokenResult = await _repository.exchangeCodeForToken(
          code: code,
          codeVerifier: flowState.codeVerifier,
        );

        // Save token if successful
        return tokenResult.fold(
          onSuccess: (token) async {
            final saveResult = await _repository.saveToken(token);
            return saveResult.fold(
              onSuccess: (_) => success(token),
              onFailure: (f) => f as Failure<Token>,
            );
          },
          onFailure: (f) => f as Failure<Token>,
        );
      },
      onFailure: (f) => f as Failure<Token>,
    );
  }
}
