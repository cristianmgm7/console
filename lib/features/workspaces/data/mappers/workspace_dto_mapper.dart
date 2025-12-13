import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/domain_referral.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/retention_policy.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_setting.dart';

/// Extension methods to convert DTOs to domain entities
extension WorkspaceDtoMapper on WorkspaceDto {
  Workspace toDomain() {
    return Workspace(
      id: id,
      name: name,
      type: WorkspaceType.fromString(type),
      planType: PlanType.fromString(planType),
      createdAt: createdAt,
      vanityName: vanityName.isEmpty ? null : vanityName,
      description: description.isEmpty ? null : description,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      lastUpdatedAt: lastUpdatedAt,
      users: users
          .map((dto) {
            try {
              return dto.toDomain();
            } on Exception {
              // Skip invalid user entries
              return null;
            }
          })
          .whereType<WorkspaceUser>()
          .toList(),
      phones: phones
          .map((dto) {
            try {
              return dto.toDomain();
            } on Exception {
              // Skip invalid phone entries
              return null;
            }
          })
          .whereType<WorkspacePhone>()
          .toList(),
      settings: settings.map(
        (key, value) => MapEntry(key, value.toDomain()),
      ),
      backgroundColor: backgroundColor.isEmpty ? null : backgroundColor,
      watermarkImageUrl: watermarkImageUrl.isEmpty ? null : watermarkImageUrl,
      conversationDefault: conversationDefault,
      invitationMode: InvitationMode.fromString(invitationMode),
      ssoEmailDomain: ssoEmailDomain.isEmpty ? null : ssoEmailDomain,
      scimProvider: scimProvider.isEmpty ? null : scimProvider,
      scimConnectionName: scimConnectionName.isEmpty ? null : scimConnectionName,
      retentionPolicy: RetentionPolicy(
        isEnabled: isRetentionEnabled,
        retentionDays: retentionDays,
        retentionDaysAsyncMeeting: retentionDaysAsyncMeeting,
        whoCanChangeConversationRetention: whoCanChangeConversationRetention
            .map(WorkspaceUserRole.fromString)
            .toList(),
        whoCanMarkMessagesAsPreserved: whoCanMarkMessagesAsPreserved
            .map(WorkspaceUserRole.fromString)
            .toList(),
      ),
      domainReferral: DomainReferral(
        mode: DomainReferralMode.fromString(domainReferralMode),
        message: domainReferralMessage,
        title: domainReferralTitle,
        domains: domains,
      ),
    );
  }
}

extension WorkspaceUserDtoMapper on WorkspaceUserDto {
  WorkspaceUser toDomain() {
    return WorkspaceUser(
      userId: userId,
      role: WorkspaceUserRole.fromString(role),
      status: WorkspaceUserStatus.fromString(status),
      statusChangedAt: statusChangedAt,
    );
  }
}

extension WorkspacePhoneDtoMapper on WorkspacePhoneDto {
  WorkspacePhone toDomain() {
    return WorkspacePhone(
      id: id,
      number: number,
      type: WorkspacePhoneType.fromString(type),
      destinationWorkspaceId: destinationWorkspaceId.isEmpty ? null : destinationWorkspaceId,
      parentPhone: parentPhone.isEmpty ? null : parentPhone,
      label: label.isEmpty ? null : label,
      messageUrl: messageUrl.isEmpty ? null : messageUrl,
      phoneSid: phoneSid.isEmpty ? null : phoneSid,
    );
  }
}

extension WorkspaceSettingDtoMapper on WorkspaceSettingDto {
  WorkspaceSetting toDomain() {
    return WorkspaceSetting(
      value: value,
      reason: WorkspaceSettingReason.fromString(reason),
    );
  }
}
