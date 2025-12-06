import 'package:carbon_voice_console/core/errors/failure_mapper.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._userRepository, this._oauthRepository) : super(const UserProfileInitial());

  final UserRepository _userRepository;
  final OAuthRepository _oauthRepository;

  /// Loads the current user profile from OAuth userinfo
  /// This should be called after authentication is established
  Future<void> loadCurrentUser() async {
    if (state is UserProfileLoading) return;

    emit(const UserProfileLoading());

    // First get user info from OAuth
    final userInfoResult = await _oauthRepository.getUserInfo();

    final userInfo = userInfoResult.fold(
      onSuccess: (info) => info,
      onFailure: (failure) {
        emit(UserProfileError(FailureMapper.mapToMessage(failure.failure)));
        return null;
      },
    );

    if (userInfo == null) return;

    // Extract user ID from userinfo - try multiple possible field names
    final userId = userInfo['client_id'] ?? userInfo['id'] ?? userInfo['sub'] ?? userInfo['userId'];
    if (userId == null) {
      emit(const UserProfileError('User ID not found in user info'));
      return;
    }

    // Now load the full user profile using the user ID
    final result = await _userRepository.getUser(userId.toString());

    result.fold(
      onSuccess: (user) {
        emit(UserProfileLoaded(user));
      },
      onFailure: (failure) {
        emit(UserProfileError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  /// Loads the current user profile by user ID (fallback method)
  /// For now, this assumes we have a way to get the current user ID
  /// This should be called after authentication is established
  Future<void> loadCurrentUserById(String userId) async {
    if (state is UserProfileLoading) return;

    emit(const UserProfileLoading());

    final result = await _userRepository.getUser(userId);

    result.fold(
      onSuccess: (user) {
        emit(UserProfileLoaded(user));
      },
      onFailure: (failure) {
        emit(UserProfileError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  /// Clears the user profile (useful for logout)
  void clearProfile() {
    emit(const UserProfileInitial());
  }

  /// Gets the current user ID if profile is loaded
  String? getCurrentUserId() {
    final currentState = state;
    if (currentState is UserProfileLoaded) {
      return currentState.user.id;
    }
    return null;
  }

  /// Gets the current user if profile is loaded
  User? getCurrentUser() {
    final currentState = state;
    if (currentState is UserProfileLoaded) {
      return currentState.user;
    }
    return null;
  }
}
