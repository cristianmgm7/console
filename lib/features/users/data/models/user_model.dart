import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
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
  /// Uses JsonNormalizer to handle API field name variations
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final normalized = JsonNormalizer.normalizeUser(json);
    
    final id = normalized['id'] as String?;
    if (id == null) {
      throw FormatException('User JSON missing required id field: $json');
    }

    return UserModel(
      id: id,
      name: normalized['name'] as String? ?? 'Unknown User',
      email: normalized['email'] as String?,
      avatarUrl: normalized['avatarUrl'] as String?,
      workspaceId: normalized['workspaceId'] as String?,
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
