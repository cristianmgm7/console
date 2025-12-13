import 'package:carbon_voice_console/features/workspaces/domain/entities/domain_referral.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/retention_policy.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_setting.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for workspace user
class WorkspaceUser extends Equatable {
  const WorkspaceUser({
    required this.userId,
    required this.role,
    required this.status,
    this.statusChangedAt,
  });

  final String userId;
  final WorkspaceUserRole role;
  final WorkspaceUserStatus status;
  final DateTime? statusChangedAt;

  @override
  List<Object?> get props => [userId, role, status, statusChangedAt];
}

/// Domain entity for workspace phone
class WorkspacePhone extends Equatable {
  const WorkspacePhone({
    required this.id,
    required this.number,
    required this.type,
    this.destinationWorkspaceId,
    this.parentPhone,
    this.label,
    this.messageUrl,
    this.phoneSid,
  });

  final String id;
  final String number;
  final WorkspacePhoneType type;
  final String? destinationWorkspaceId;
  final String? parentPhone;
  final String? label;
  final String? messageUrl;
  final String? phoneSid;

  @override
  List<Object?> get props => [
        id,
        number,
        type,
        destinationWorkspaceId,
        parentPhone,
        label,
        messageUrl,
        phoneSid,
      ];
}

/// Domain entity representing a workspace
class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    required this.type,
    required this.planType,
    required this.createdAt,
    this.vanityName,
    this.description,
    this.imageUrl,
    this.lastUpdatedAt,
    this.users = const [],
    this.phones = const [],
    this.settings = const {},
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.ssoEmailDomain,
    this.scimProvider,
    this.scimConnectionName,
    RetentionPolicy? retentionPolicy,
    DomainReferral? domainReferral,
  })  : retentionPolicy = retentionPolicy ?? const RetentionPolicy(
          isEnabled: false,
          retentionDays: 0,
          retentionDaysAsyncMeeting: 0,
          whoCanChangeConversationRetention: [],
          whoCanMarkMessagesAsPreserved: [],
        ),
        domainReferral = domainReferral ?? const DomainReferral(
          mode: DomainReferralMode.doNotInform,
          message: '',
          title: '',
          domains: [],
        );

  final String id;
  final String name;
  final WorkspaceType type;
  final PlanType planType;
  final DateTime createdAt;
  final String? vanityName;
  final String? description;
  final String? imageUrl;
  final DateTime? lastUpdatedAt;
  final List<WorkspaceUser> users;
  final List<WorkspacePhone> phones;
  final Map<String, WorkspaceSetting> settings;
  final String? backgroundColor;
  final String? watermarkImageUrl;
  final bool? conversationDefault;
  final InvitationMode? invitationMode;

  // SSO/SCIM fields
  final String? ssoEmailDomain;
  final String? scimProvider;
  final String? scimConnectionName;

  // Value objects for grouped concepts
  final RetentionPolicy retentionPolicy;
  final DomainReferral domainReferral;

  // Legacy compatibility - expose retention fields directly
  bool get isRetentionEnabled => retentionPolicy.isEnabled;
  int get retentionDays => retentionPolicy.retentionDays;
  List<String> get domains => domainReferral.domains;

  /// Gets the current user's role in this workspace (if available)
  WorkspaceUserRole? getCurrentUserRole(String currentUserId) {
    final user = users.where((u) => u.userId == currentUserId).firstOrNull;
    return user?.role;
  }

  /// Checks if this workspace should be hidden from lists
  bool get shouldBeHidden => type == WorkspaceType.personallink;

  /// Checks if current user is admin or member
  bool isAdminOrMember(String currentUserId) {
    final role = getCurrentUserRole(currentUserId);
    return role == WorkspaceUserRole.admin ||
           role == WorkspaceUserRole.member ||
           role == WorkspaceUserRole.owner;
  }

  /// Checks if current user is a guest
  bool isGuest(String currentUserId) {
    final role = getCurrentUserRole(currentUserId);
    return role == WorkspaceUserRole.guest;
  }

  /// Gets workspace classification category
  WorkspaceCategory getCategory(String currentUserId) {
    if (shouldBeHidden) {
      return WorkspaceCategory.hidden;
    }

    if (type == WorkspaceType.personal) {
      return WorkspaceCategory.personal;
    }

    if (type == WorkspaceType.webcontact) {
      return WorkspaceCategory.webcontact;
    }

    // Standard or workspace type
    if (type == WorkspaceType.standard || type == WorkspaceType.workspace) {
      if (isAdminOrMember(currentUserId)) {
        return WorkspaceCategory.standardMember;
      } else if (isGuest(currentUserId)) {
        return WorkspaceCategory.standardGuest;
      }
    }

    return WorkspaceCategory.unknown;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        planType,
        createdAt,
        vanityName,
        description,
        imageUrl,
        lastUpdatedAt,
        users,
        phones,
        settings,
        backgroundColor,
        watermarkImageUrl,
        conversationDefault,
        invitationMode,
        ssoEmailDomain,
        scimProvider,
        scimConnectionName,
        retentionPolicy,
        domainReferral,
      ];
}

/// Workspace classification categories for sorting/filtering
enum WorkspaceCategory {
  /// Personal workspace
  personal,

  /// Standard/workspace where user is admin or member
  standardMember,

  /// Standard/workspace where user is guest
  standardGuest,

  /// Webcontact workspace
  webcontact,

  /// Hidden workspace (personallink)
  hidden,

  /// Unknown category
  unknown,
}
