import 'package:json_annotation/json_annotation.dart';

part 'workspace_phone_dto.g.dart';

/// DTO for workspace phone from API response
@JsonSerializable()
class WorkspacePhoneDto {
  const WorkspacePhoneDto({
    this.id,
    this.destinationWorkspaceId,
    this.number,
    this.parentPhone,
    this.type,
    this.label,
    this.messageUrl,
    this.phoneSid,
  });

  factory WorkspacePhoneDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspacePhoneDtoFromJson(json);

  /// Accepts alternate keys commonly seen in phone payloads.
  factory WorkspacePhoneDto.fromApiJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['_id'] ??=
        json['phone_guid'] ?? json['id'] ?? json['_id'] ?? json['phone_id'];
    normalized['number'] ??= json['number'] ?? json['phone'];
    normalized['type'] ??= json['type'] ?? json['type_cd'] ?? json['channel_type'];
    normalized['destination_workspace_id'] ??=
        json['destination_workspace_id'] ?? json['workspace_guid'];
    normalized['parent_phone'] ??= json['parent_phone'];
    normalized['label'] ??= json['label'];
    normalized['message_url'] ??= json['message_url'] ?? json['url'];
    normalized['phone_sid'] ??= json['phone_sid'];
    return _$WorkspacePhoneDtoFromJson(normalized);
  }

  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'destination_workspace_id')
  final String? destinationWorkspaceId;

  final String? number;

  @JsonKey(name: 'parent_phone')
  final String? parentPhone;

  final String? type;

  final String? label;

  @JsonKey(name: 'message_url')
  final String? messageUrl;

  @JsonKey(name: 'phone_sid')
  final String? phoneSid;

  Map<String, dynamic> toJson() => _$WorkspacePhoneDtoToJson(this);
}
