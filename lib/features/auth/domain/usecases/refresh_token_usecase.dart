import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

@LazySingleton()
class RefreshTokenUseCase {
  final AuthRepository _repository;

  const RefreshTokenUseCase(this._repository);

  Future<Result<Token>> call() async {
    final currentTokenResult = await _repository.loadSavedToken();

    return currentTokenResult.fold(
      onSuccess: (token) async {
        if (token == null || token.refreshToken == null) {
          return failure<Token>(const TokenExpiredFailure());
        }

        final refreshResult = await _repository.refreshToken(token.refreshToken!);

        return refreshResult.fold(
          onSuccess: (newToken) async {
            await _repository.saveToken(newToken);
            return success(newToken);
          },
          onFailure: (f) => f as Failure<Token>,
        );
      },
      onFailure: (f) => f as Failure<Token>,
    );
  }
}
