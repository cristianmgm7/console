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

  /// Accepts API payloads with alternative key names and normalizes them
  /// before delegating to the generated `fromJson`.
  factory WorkspaceDto.fromApiJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    DateTime? _parseEpochOrString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        // If it's already an ISO string, use it directly
        return DateTime.tryParse(value);
      }
      if (value is int) {
        // Detect seconds vs millis
        final millis = value > 1000000000000 ? value : value * 1000;
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      return null;
    }

    normalized['_id'] ??=
        json['workspace_guid'] ?? json['_id'] ?? json['id'] ?? json['workspace_id'];
    normalized['name'] ??=
        json['workspace_name'] ?? json['name'] ?? json['workspaceName'];
    normalized['description'] ??=
        json['workspace_description'] ?? json['description'];
    normalized['type'] ??=
        json['type'] ?? json['type_cd'] ?? json['workspace_type'];
    normalized['plan_type'] ??= json['plan_type'] ?? json['plan'];
    normalized['created_at'] ??= json['created_at'] ?? json['createdAt'];
    normalized['last_updated_at'] ??=
        json['last_updated_at'] ?? json['updated_at'];
    normalized['vanity_name'] ??= json['vanity_name'] ?? json['vanityName'];
    normalized['image_url'] ??= json['image_url'] ?? json['imageUrl'];
    normalized['background_color'] ??=
        json['background_color'] ?? json['backgroundColor'];
    normalized['watermark_image_url'] ??=
        json['watermark_image_url'] ?? json['watermarkImageUrl'];
    normalized['conversation_default'] ??=
        json['conversation_default'] ?? json['conversationDefault'];
    normalized['invitation_mode'] ??=
        json['invitation_mode'] ?? json['invitationMode'];
    normalized['sso_email_domain'] ??= json['sso_email_domain'];
    normalized['is_retention_enabled'] ??= json['is_retention_enabled'];
    normalized['retention_days'] ??= json['retention_days'];
    normalized['who_can_change_conversation_retention'] ??=
        json['who_can_change_conversation_retention'];
    normalized['who_can_mark_messages_as_preserved'] ??=
        json['who_can_mark_messages_as_preserved'];
    normalized['retention_days_async_meeting'] ??=
        json['retention_days_async_meeting'];

    // Collections
    if (json['collaborators'] is List) {
      normalized['users'] = (json['collaborators'] as List)
          .whereType<Map<String, dynamic>>()
          .map((u) => WorkspaceUserDto.fromApiJson(u).toJson())
          .toList();
    } else {
      normalized['users'] ??= json['users'];
    }

    if (json['phones'] is List) {
      normalized['phones'] = (json['phones'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => WorkspacePhoneDto.fromApiJson(p).toJson())
          .toList();
    }
    normalized['phones'] ??= json['phones'];
    normalized['settings'] ??= json['settings'];

    // Ensure domains is a list of strings if present
    final domains = json['domains'];
    if (domains is List) {
      normalized['domains'] = domains.map((e) => e.toString()).toList();
    }

    // Normalize timestamps to ISO strings for the generated parser
    final createdTs = _parseEpochOrString(json['created_ts']) ??
        _parseEpochOrString(normalized['created_at']);
    if (createdTs != null) {
      normalized['created_at'] = createdTs.toIso8601String();
    }

    final updatedTs = _parseEpochOrString(json['last_updated_ts']) ??
        _parseEpochOrString(normalized['last_updated_at']);
    if (updatedTs != null) {
      normalized['last_updated_at'] = updatedTs.toIso8601String();
    }

    return _$WorkspaceDtoFromJson(normalized);
  }

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
