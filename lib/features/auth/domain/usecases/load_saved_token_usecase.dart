import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

@LazySingleton()
class LoadSavedTokenUseCase {
  final AuthRepository _repository;

  const LoadSavedTokenUseCase(this._repository);

  Future<Result<Token?>> call() {
    return _repository.loadSavedToken();
  }
}
