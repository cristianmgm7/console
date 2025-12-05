import 'package:json_annotation/json_annotation.dart';

part 'workspace_setting_dto.g.dart';

/// DTO for workspace setting value from API response
@JsonSerializable()
class WorkspaceSettingDto {
  const WorkspaceSettingDto({
    this.value,
    this.reason,
  });

  factory WorkspaceSettingDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceSettingDtoFromJson(json);

  final bool? value;

  final String? reason;

  Map<String, dynamic> toJson() => _$WorkspaceSettingDtoToJson(this);
}
