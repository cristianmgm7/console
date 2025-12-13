import 'package:json_annotation/json_annotation.dart';

part 'workspace_user_dto.g.dart';

/// DTO for workspace user from API response
@JsonSerializable()
class WorkspaceUserDto {
  const WorkspaceUserDto({
    required this.userId,
    required this.role,
    required this.statusChangedAt,
    required this.status,
  });

  factory WorkspaceUserDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceUserDtoFromJson(json);

  @JsonKey(name: 'user_id')
  final String userId;

  final String role;

  @JsonKey(name: 'status_changed_at')
  final DateTime statusChangedAt;

  final String status;

  Map<String, dynamic> toJson() => _$WorkspaceUserDtoToJson(this);
}
