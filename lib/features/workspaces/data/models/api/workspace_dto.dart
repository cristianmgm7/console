import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_dto.g.dart';

/// DTO for workspace from API response - EXACT schema match, no normalization
@JsonSerializable()
class WorkspaceDto {
  const WorkspaceDto({
    required this.id,
    required this.vanityName,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.planType,
    required this.users,
    required this.settings,
    required this.phones,
    required this.backgroundColor,
    required this.watermarkImageUrl,
    required this.conversationDefault,
    required this.invitationMode,
    required this.ssoEmailDomain,
    required this.scimProvider,
    required this.scimConnectionName,
    required this.isRetentionEnabled,
    required this.retentionDays,
    required this.whoCanChangeConversationRetention,
    required this.whoCanMarkMessagesAsPreserved,
    required this.retentionDaysAsyncMeeting,
    required this.domainReferralMode,
    required this.domainReferralMessage,
    required this.domainReferralTitle,
    required this.domains,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'vanity_name')
  final String vanityName;

  final String name;

  final String description;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  final String type;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime lastUpdatedAt;

  @JsonKey(name: 'plan_type')
  final String planType;

  final List<WorkspaceUserDto> users;
  final Map<String, WorkspaceSettingDto> settings;
  final List<WorkspacePhoneDto> phones;

  @JsonKey(name: 'background_color')
  final String backgroundColor;

  @JsonKey(name: 'watermark_image_url')
  final String watermarkImageUrl;

  @JsonKey(name: 'conversation_default')
  final bool conversationDefault;

  @JsonKey(name: 'invitation_mode')
  final String invitationMode;

  @JsonKey(name: 'sso_email_domain')
  final String ssoEmailDomain;

  @JsonKey(name: 'scim_provider')
  final String scimProvider;

  @JsonKey(name: 'scim_connection_name')
  final String scimConnectionName;

  @JsonKey(name: 'is_retention_enabled')
  final bool isRetentionEnabled;

  @JsonKey(name: 'retention_days')
  final int retentionDays;

  @JsonKey(name: 'who_can_change_conversation_retention')
  final List<String> whoCanChangeConversationRetention;

  @JsonKey(name: 'who_can_mark_messages_as_preserved')
  final List<String> whoCanMarkMessagesAsPreserved;

  @JsonKey(name: 'retention_days_async_meeting')
  final int retentionDaysAsyncMeeting;

  @JsonKey(name: 'domain_referral_mode')
  final String domainReferralMode;

  @JsonKey(name: 'domain_referral_message')
  final String domainReferralMessage;

  @JsonKey(name: 'domain_referral_title')
  final String domainReferralTitle;

  final List<String> domains;

  Map<String, dynamic> toJson() => _$WorkspaceDtoToJson(this);
}
