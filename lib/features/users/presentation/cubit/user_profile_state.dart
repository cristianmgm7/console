import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

sealed class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {
  const UserProfileInitial();
}

class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

class UserProfileLoaded extends UserProfileState {
  const UserProfileLoaded(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

class UserProfileError extends UserProfileState {
  const UserProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
