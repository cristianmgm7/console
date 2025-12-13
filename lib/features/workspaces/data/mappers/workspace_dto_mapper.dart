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
      name: name ?? 'Unknown Workspace',
      type: WorkspaceType.fromString(type ?? 'unknown'),
      planType: PlanType.fromString(planType ?? 'unknown'),
      createdAt: createdAt ?? DateTime.now(),
      vanityName: vanityName?.isEmpty ?? true ? null : vanityName,
      description: description?.isEmpty ?? true ? null : description,
      imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl,
      lastUpdatedAt: lastUpdatedAt,
      users: users
          ?.map((dto) {
            try {
              return dto.toDomain();
            } on Exception {
              // Skip invalid user entries
              return null;
            }
          })
          .whereType<WorkspaceUser>()
          .toList() ?? [],
      phones: phones
          ?.map((dto) {
            try {
              return dto.toDomain();
            } on Exception {
              // Skip invalid phone entries
              return null;
            }
          })
          .whereType<WorkspacePhone>()
          .toList() ?? [],
      settings: settings?.map(
        (key, value) => MapEntry(key, value.toDomain()),
      ) ?? {},
      backgroundColor: backgroundColor?.isEmpty ?? true ? null : backgroundColor,
      watermarkImageUrl: watermarkImageUrl?.isEmpty ?? true ? null : watermarkImageUrl,
      conversationDefault: conversationDefault,
      invitationMode: InvitationMode.fromString(invitationMode ?? 'unknown'),
      ssoEmailDomain: ssoEmailDomain?.isEmpty ?? true ? null : ssoEmailDomain,
      scimProvider: scimProvider?.isEmpty ?? true ? null : scimProvider,
      scimConnectionName: scimConnectionName?.isEmpty ?? true ? null : scimConnectionName,
      retentionPolicy: RetentionPolicy(
        isEnabled: isRetentionEnabled ?? false,
        retentionDays: retentionDays ?? 0,
        retentionDaysAsyncMeeting: retentionDaysAsyncMeeting ?? 0,
        whoCanChangeConversationRetention: whoCanChangeConversationRetention
            ?.map(WorkspaceUserRole.fromString)
            .toList() ?? [],
        whoCanMarkMessagesAsPreserved: whoCanMarkMessagesAsPreserved
            ?.map(WorkspaceUserRole.fromString)
            .toList() ?? [],
      ),
      domainReferral: DomainReferral(
        mode: DomainReferralMode.fromString(domainReferralMode ?? 'do_not_inform'),
        message: domainReferralMessage ?? '',
        title: domainReferralTitle ?? '',
        domains: domains ?? [],
      ),
    );
  }
}

extension WorkspaceUserDtoMapper on WorkspaceUserDto {
  WorkspaceUser toDomain() {
    return WorkspaceUser(
      userId: userId,
      role: WorkspaceUserRole.fromString(role ?? 'unknown'),
      status: WorkspaceUserStatus.fromString(status ?? 'unknown'),
      statusChangedAt: statusChangedAt,
    );
  }
}

extension WorkspacePhoneDtoMapper on WorkspacePhoneDto {
  WorkspacePhone toDomain() {
    return WorkspacePhone(
      id: id,
      number: number ?? '',
      type: WorkspacePhoneType.fromString(type ?? 'unknown'),
      destinationWorkspaceId: destinationWorkspaceId?.isEmpty ?? true ? null : destinationWorkspaceId,
      parentPhone: parentPhone?.isEmpty ?? true ? null : parentPhone,
      label: label?.isEmpty ?? true ? null : label,
      messageUrl: messageUrl?.isEmpty ?? true ? null : messageUrl,
      phoneSid: phoneSid?.isEmpty ?? true ? null : phoneSid,
    );
  }
}

extension WorkspaceSettingDtoMapper on WorkspaceSettingDto {
  WorkspaceSetting toDomain() {
    return WorkspaceSetting(
      value: value ?? false,
      reason: WorkspaceSettingReason.fromString(reason ?? 'unknown'),
    );
  }
}
