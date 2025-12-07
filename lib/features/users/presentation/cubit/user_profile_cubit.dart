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

    // Get user using the use case
    final userResult = await _getCurrentUserInfoUsecase.call();

    userResult.fold(
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
