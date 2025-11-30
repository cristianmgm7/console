import 'package:carbon_voice_console/dtos/permission_dto.dart';
import 'package:carbon_voice_console/dtos/workspace_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

/// DTO that mirrors the exact JSON structure from the user profile API
@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.permissions,
    this.workspaces,
    this.channels,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  final String? id;
  final String? email;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  final Map<String, PermissionDto>? permissions;
  final List<WorkspaceDto>? workspaces;
  final List<dynamic>? channels;
}
