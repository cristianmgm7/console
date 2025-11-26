import 'package:equatable/equatable.dart';

/// Domain entity representing a user
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.workspaceId,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? workspaceId;

  @override
  List<Object?> get props => [id, name, email, avatarUrl, workspaceId];
}

