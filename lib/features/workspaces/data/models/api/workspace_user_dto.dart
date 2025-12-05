import 'package:json_annotation/json_annotation.dart';

part 'workspace_user_dto.g.dart';

/// DTO for workspace user from API response
@JsonSerializable()
class WorkspaceUserDto {
  const WorkspaceUserDto({
    this.userId,
    this.role,
    this.statusChangedAt,
    this.status,
  });

  factory WorkspaceUserDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceUserDtoFromJson(json);

  /// Accepts alternate keys commonly seen in collaborators payloads.
  factory WorkspaceUserDto.fromApiJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['user_id'] ??=
        json['user_guid'] ?? json['guid'] ?? json['_id'] ?? json['id'];
    normalized['role'] ??= json['role_cd'] ?? json['role'];
    normalized['status'] ??= json['status'];
    normalized['status_changed_at'] ??= json['status_changed_at'];
    return _$WorkspaceUserDtoFromJson(normalized);
  }

  @JsonKey(name: 'user_id')
  final String? userId;

  final String? role;

  @JsonKey(name: 'status_changed_at')
  final DateTime? statusChangedAt;

  final String? status;

  Map<String, dynamic> toJson() => _$WorkspaceUserDtoToJson(this);
}
