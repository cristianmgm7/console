import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case for fetching current user information
/// This use case coordinates between OAuth repository and User repository
/// to fetch user profile data that should be cached by the user data layer
@injectable
class GetCurrentUserInfoUsecase {
  const GetCurrentUserInfoUsecase(
    this._oauthRepository,
    this._userRepository,
    this._logger,
  );

  final OAuthRepository _oauthRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  /// Fetches current user information from the API
  ///
  /// This method first checks authentication status via OAuth repository,
  /// then delegates the actual data fetching to the User repository which
  /// handles caching and API calls through the remote data source.
  Future<Result<User>> call() async {
    try {
      // First check if user is authenticated
      final authResult = await _oauthRepository.isAuthenticated();
      final isAuthenticated = authResult.fold(
        onSuccess: (isAuth) => isAuth,
        onFailure: (_) => false,
      );

      if (!isAuthenticated) {
        return failure(const AuthFailure(
          code: 'NOT_AUTHENTICATED',
          details: 'User is not authenticated',
        ));
      }

      // Delegate to user repository which will handle caching and API calls
      return await _userRepository.getCurrentUserInfo();
    } on Exception catch (e, stack) {
      _logger.e('Error in GetCurrentUserInfoUsecase', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
