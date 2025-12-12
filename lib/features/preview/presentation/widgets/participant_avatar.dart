import 'package:equatable/equatable.dart';

/// Participant for avatar display
class ParticipantAvatar extends Equatable {
  const ParticipantAvatar({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, fullName, avatarUrl];
}
