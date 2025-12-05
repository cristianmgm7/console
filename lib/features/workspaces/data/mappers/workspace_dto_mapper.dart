import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';

/// Extension methods to convert DTOs to domain entities
extension WorkspaceDtoMapper on WorkspaceDto {
  Workspace toDomain() {
    // Validate required fields
    if (id == null || name == null) {
      throw FormatException(
        'Required workspace fields are missing: id=${id == null}, name=${name == null}',
      );
    }

    return Workspace(
      id: id!,
      name: name!,
      type: WorkspaceType.fromString(type),
      planType: PlanType.fromString(planType),
      createdAt: createdAt ?? DateTime.now(),
      vanityName: vanityName,
      description: description,
      imageUrl: imageUrl,
      lastUpdatedAt: lastUpdatedAt,
      users: users == null
          ? []
          : users!
              .map((dto) {
                try {
                  return dto.toDomain();
                } on FormatException {
                  // Skip invalid user entries rather than failing the workspace
                  return null;
                }
              })
              .whereType<WorkspaceUser>()
              .toList(),
      phones: phones == null
          ? []
          : phones!
              .map((dto) {
                try {
                  return dto.toDomain();
                } on FormatException {
                  // Skip invalid phone entries rather than failing the workspace
                  return null;
                }
              })
              .whereType<WorkspacePhone>()
              .toList(),
      backgroundColor: backgroundColor,
      watermarkImageUrl: watermarkImageUrl,
      conversationDefault: conversationDefault,
      invitationMode: InvitationMode.fromString(invitationMode),
      isRetentionEnabled: isRetentionEnabled,
      retentionDays: retentionDays,
      domains: domains ?? [],
    );
  }
}

extension WorkspaceUserDtoMapper on WorkspaceUserDto {
  WorkspaceUser toDomain() {
    if (userId == null) {
      throw const FormatException('WorkspaceUser missing required userId');
    }

    return WorkspaceUser(
      userId: userId!,
      role: WorkspaceUserRole.fromString(role),
      status: WorkspaceUserStatus.fromString(status),
      statusChangedAt: statusChangedAt,
    );
  }
}

extension WorkspacePhoneDtoMapper on WorkspacePhoneDto {
  WorkspacePhone toDomain() {
    if (id == null || number == null) {
      throw FormatException(
        'WorkspacePhone missing required fields: id=${id == null}, number=${number == null}',
      );
    }

    return WorkspacePhone(
      id: id!,
      number: number!,
      type: WorkspacePhoneType.fromString(type),
      destinationWorkspaceId: destinationWorkspaceId,
      parentPhone: parentPhone,
      label: label,
      messageUrl: messageUrl,
      phoneSid: phoneSid,
    );
  }
}
