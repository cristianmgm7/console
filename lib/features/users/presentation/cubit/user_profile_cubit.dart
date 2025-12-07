import 'package:carbon_voice_console/core/errors/failure_mapper.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/usecases/get_current_user_info_usecase.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._getCurrentUserInfoUsecase) : super(const UserProfileInitial());

  final GetCurrentUserInfoUsecase _getCurrentUserInfoUsecase;

  /// Loads the current user profile from /whoami endpoint
  /// This should be called after authentication is established
  Future<void> loadCurrentUser() async {
    if (state is UserProfileLoading) return;

    emit(const UserProfileLoading());

    // Get user info using the use case
    final userInfoResult = await _getCurrentUserInfoUsecase.call();

    final userInfo = userInfoResult.fold(
      onSuccess: (info) => info,
      onFailure: (failure) {
        emit(UserProfileError(FailureMapper.mapToMessage(failure.failure)));
        return null;
      },
    );

    if (userInfo == null) return;

    // Extract user data from the response
    final dynamic userIdValue = userInfo['user_guid'] ?? userInfo['uuid'] ?? userInfo['id'] ?? userInfo['user_id'] ?? userInfo['userId'] ?? userInfo['sub'];
    final userId = userIdValue?.toString();

    if (userId == null) {
      emit(const UserProfileError('No user ID found in user info response'));
      return;
    }

    // Extract user profile data
    final name = userInfo['name']?.toString() ??
                userInfo['full_name']?.toString() ??
                userInfo['display_name']?.toString() ??
                'Unknown User';

    final email = userInfo['email']?.toString();

    // Create user entity directly from session data
    final user = User(
      id: userId,
      name: name,
      email: email,
      // avatarUrl and workspaceId can be added if available in session data
    );

    emit(UserProfileLoaded(user));
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
