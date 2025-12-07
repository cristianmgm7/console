import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfileDto {

  UserProfileDto({
    this.userGuid,
    this.uuid,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.isVerified,
    this.isAllowedThroughGate,
    this.email,
    this.phone,
    this.workspaceGuids,
    this.identities,
    this.entries,
    this.lastSeenOn,
    this.notificationSettings,
    this.languages,
    this.voiceGender,
    this.voiceId,
    this.hasFcmToken,
    this.ttsMode,
    this.translationMode,
    this.preserveSendersVoice,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);
  @JsonKey(name: 'user_guid')
  final String? userGuid;

  final String? uuid;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'is_verified')
  final String? isVerified;

  @JsonKey(name: 'is_allowed_through_gate')
  final bool? isAllowedThroughGate;

  @JsonKey(name: 'email_txt')
  final String? email;

  @JsonKey(name: 'phone_txt')
  final String? phone;

  @JsonKey(name: 'workspace_guids')
  final List<String>? workspaceGuids;

  final List<IdentityDto>? identities;

  final List<EntryDto>? entries;

  @JsonKey(name: 'last_seen_on')
  final String? lastSeenOn; // Parse to DateTime in the Entity

  @JsonKey(name: 'notification_settings')
  final NotificationSettingsDto? notificationSettings;

  final List<String>? languages;

  @JsonKey(name: 'voice_gender')
  final String? voiceGender;

  @JsonKey(name: 'voice_id')
  final String? voiceId;

  @JsonKey(name: 'has_fcm_token')
  final bool? hasFcmToken;

  @JsonKey(name: 'tts_mode')  
  final String? ttsMode;

  @JsonKey(name: 'translation_mode')
  final String? translationMode;

  @JsonKey(name: 'preserve_senders_voice')
  final bool? preserveSendersVoice;

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class IdentityDto {

  IdentityDto({
    this.provider,
    this.providerId,
    this.email,
  });

  factory IdentityDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityDtoFromJson(json);
  final String? provider;
  final String? providerId;
  final String? email;

  Map<String, dynamic> toJson() => _$IdentityDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EntryDto {

  EntryDto({
    this.id,
    this.type,
    this.value,
  });

  factory EntryDto.fromJson(Map<String, dynamic> json) =>
      _$EntryDtoFromJson(json);
  final String? id;
  final String? type;
  final String? value;

  Map<String, dynamic> toJson() => _$EntryDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotificationSettingsDto {

  NotificationSettingsDto({
    this.emailNotifications,
    this.pushNotifications,
    this.smsNotifications,
  });

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsDtoFromJson(json);
  @JsonKey(name: 'email_notifications')
  final bool? emailNotifications;

  @JsonKey(name: 'push_notifications')
  final bool? pushNotifications;

  @JsonKey(name: 'sms_notifications')
  final bool? smsNotifications;

  Map<String, dynamic> toJson() => _$NotificationSettingsDtoToJson(this);
}

extension UserProfileMapper on UserProfileDto {
  User toEntity() {
    return User(
      id: userGuid ?? 'unknown',
      firstName: firstName ?? 'Unknown',
      lastName: lastName ?? 'User',
      email: email ?? '',
      isVerified: isVerified == 'Y',
      avatarUrl: imageUrl,
      lastSeen: lastSeenOn != null ? DateTime.tryParse(lastSeenOn!) : null,
      languages: languages ?? [],
    );
  }
}
