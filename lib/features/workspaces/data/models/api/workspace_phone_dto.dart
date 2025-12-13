import 'package:json_annotation/json_annotation.dart';

part 'workspace_phone_dto.g.dart';

/// DTO for workspace phone from API response
@JsonSerializable()
class WorkspacePhoneDto {
  const WorkspacePhoneDto({
    required this.id,
    required this.destinationWorkspaceId,
    required this.number,
    required this.parentPhone,
    required this.type,
    required this.label,
    required this.messageUrl,
    required this.phoneSid,
  });

  factory WorkspacePhoneDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspacePhoneDtoFromJson(json);

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'destination_workspace_id')
  final String destinationWorkspaceId;

  final String number;

  @JsonKey(name: 'parent_phone')
  final String parentPhone;

  final String type;

  final String label;

  @JsonKey(name: 'message_url')
  final String messageUrl;

  @JsonKey(name: 'phone_sid')
  final String phoneSid;

  Map<String, dynamic> toJson() => _$WorkspacePhoneDtoToJson(this);
}
