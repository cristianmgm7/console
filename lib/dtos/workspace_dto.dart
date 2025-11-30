import 'package:json_annotation/json_annotation.dart';

part 'workspace_dto.g.dart';

/// DTO for workspace configuration
@JsonSerializable()
class WorkspaceDto {
  const WorkspaceDto({
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.ssoEmailDomain,
    this.retentionDays,
    this.whoCanChangeConversationRetention,
    this.whoCanMarkMessagesAsPreserved,
    this.retentionDaysAsyncMeeting,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceDtoToJson(this);

  @JsonKey(name: 'background_color')
  final String? backgroundColor;

  @JsonKey(name: 'watermark_image_url')
  final String? watermarkImageUrl;

  @JsonKey(name: 'conversation_default')
  final bool? conversationDefault;

  @JsonKey(name: 'invitation_mode')
  final String? invitationMode;

  @JsonKey(name: 'sso_email_domain')
  final String? ssoEmailDomain;

  @JsonKey(name: 'retention_days')
  final int? retentionDays;

  @JsonKey(name: 'who_can_change_conversation_retention')
  final List<dynamic>? whoCanChangeConversationRetention;

  @JsonKey(name: 'who_can_mark_messages_as_preserved')
  final List<dynamic>? whoCanMarkMessagesAsPreserved;

  @JsonKey(name: 'retention_days_async_meeting')
  final int? retentionDaysAsyncMeeting;
}
