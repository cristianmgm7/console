import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_dto.g.dart';

// Custom converter for WorkspaceUserDto list
class WorkspaceUserListConverter
    implements JsonConverter<List<WorkspaceUserDto>, List<dynamic>?> {
  const WorkspaceUserListConverter();

  @override
  List<WorkspaceUserDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => WorkspaceUserDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<WorkspaceUserDto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for WorkspacePhoneDto list
class WorkspacePhoneListConverter
    implements JsonConverter<List<WorkspacePhoneDto>, List<dynamic>?> {
  const WorkspacePhoneListConverter();

  @override
  List<WorkspacePhoneDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => WorkspacePhoneDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<WorkspacePhoneDto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for settings map
class WorkspaceSettingsConverter
    implements
        JsonConverter<Map<String, WorkspaceSettingDto>, Map<String, dynamic>?> {
  const WorkspaceSettingsConverter();

  @override
  Map<String, WorkspaceSettingDto> fromJson(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map(
      (key, value) => MapEntry(
        key,
        WorkspaceSettingDto.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(Map<String, WorkspaceSettingDto> object) =>
      object.map((key, value) => MapEntry(key, value.toJson()));
}

/// DTO for workspace from API response
@JsonSerializable()
class WorkspaceDto {
  const WorkspaceDto({
    this.id,
    this.vanityName,
    this.name,
    this.description,
    this.imageUrl,
    this.type,
    this.createdAt,
    this.lastUpdatedAt,
    this.planType,
    this.users,
    this.settings,
    this.phones,
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.ssoEmailDomain,
    this.scimProvider,
    this.scimConnectionName,
    this.isRetentionEnabled,
    this.retentionDays,
    this.whoCanChangeConversationRetention,
    this.whoCanMarkMessagesAsPreserved,
    this.retentionDaysAsyncMeeting,
    this.domainReferralMode,
    this.domainReferralMessage,
    this.domainReferralTitle,
    this.domains,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);

  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'vanity_name')
  final String? vanityName;

  final String? name;

  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final String? type;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime? lastUpdatedAt;

  @JsonKey(name: 'plan_type')
  final String? planType;

  @WorkspaceUserListConverter()
  final List<WorkspaceUserDto>? users;

  @WorkspaceSettingsConverter()
  final Map<String, WorkspaceSettingDto>? settings;

  @WorkspacePhoneListConverter()
  final List<WorkspacePhoneDto>? phones;

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

  @JsonKey(name: 'scim_provider')
  final String? scimProvider;

  @JsonKey(name: 'scim_connection_name')
  final String? scimConnectionName;

  @JsonKey(name: 'is_retention_enabled')
  final bool? isRetentionEnabled;

  @JsonKey(name: 'retention_days')
  final int? retentionDays;

  @JsonKey(name: 'who_can_change_conversation_retention')
  final List<String>? whoCanChangeConversationRetention;

  @JsonKey(name: 'who_can_mark_messages_as_preserved')
  final List<String>? whoCanMarkMessagesAsPreserved;

  @JsonKey(name: 'retention_days_async_meeting')
  final int? retentionDaysAsyncMeeting;

  @JsonKey(name: 'domain_referral_mode')
  final String? domainReferralMode;

  @JsonKey(name: 'domain_referral_message')
  final String? domainReferralMessage;

  @JsonKey(name: 'domain_referral_title')
  final String? domainReferralTitle;

  final List<String>? domains;

  Map<String, dynamic> toJson() => _$WorkspaceDtoToJson(this);
}
