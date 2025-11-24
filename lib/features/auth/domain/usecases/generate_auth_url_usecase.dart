import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

@LazySingleton()
class GenerateAuthUrlUseCase {
  final AuthRepository _repository;

  const GenerateAuthUrlUseCase(this._repository);

  Future<Result<String>> call() {
    return _repository.generateAuthorizationUrl();
  }
}
