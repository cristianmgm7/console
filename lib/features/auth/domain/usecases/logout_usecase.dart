import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

@LazySingleton()
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
