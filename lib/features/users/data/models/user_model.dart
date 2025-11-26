import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Data model for user with JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.email,
    super.avatarUrl,
    super.workspaceId,
  });

  /// Creates a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? json['userId'] as String,
      name: json['name'] as String? ?? json['username'] as String? ?? 'Unknown User',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String?,
    );
  }

  /// Converts UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (workspaceId != null) 'workspaceId': workspaceId,
    };
  }

  /// Converts to domain entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      workspaceId: workspaceId,
    );
  }
}
