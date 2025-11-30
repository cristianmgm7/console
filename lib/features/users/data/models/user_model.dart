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

  /// Creates a UserModel from normalized JSON
  /// Expects JSON already normalized by JsonNormalizer at data source boundary
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw FormatException('User JSON missing required id field: $json');
    }

    return UserModel(
      id: id,
      name: json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      workspaceId: json['workspaceId'] as String?,
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
