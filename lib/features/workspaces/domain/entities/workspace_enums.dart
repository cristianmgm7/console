/// Workspace type classification
enum WorkspaceType {
  /// Personal workspace
  personal('personal'),

  /// Standard workspace
  standard('standard'),

  /// Legacy workspace type
  workspace('workspace'),

  /// Web contact workspace
  webcontact('webcontact'),

  /// Personal link workspace (should be hidden from lists)
  personallink('personallink'),

  /// Unknown/unrecognized type
  unknown('unknown');

  const WorkspaceType(this.value);
  final String value;

  static WorkspaceType fromString(String? value) {
    if (value == null) return WorkspaceType.unknown;
    return WorkspaceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceType.unknown,
    );
  }
}

/// Workspace plan type
enum PlanType {
  /// Free plan
  free('free'),

  /// Standard plan
  standard('standard'),

  /// Pro plan
  pro('pro'),

  /// Enterprise plan
  enterprise('enterprise'),

  /// Unknown plan
  unknown('unknown');

  const PlanType(this.value);
  final String value;

  static PlanType fromString(String? value) {
    if (value == null) return PlanType.unknown;
    return PlanType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlanType.unknown,
    );
  }
}

/// User role in workspace
enum WorkspaceUserRole {
  /// Administrator
  admin('admin'),

  /// Regular member
  member('member'),

  /// Guest user
  guest('guest'),

  /// Owner
  owner('owner'),

  /// Unknown role
  unknown('unknown');

  const WorkspaceUserRole(this.value);
  final String value;

  static WorkspaceUserRole fromString(String? value) {
    if (value == null) return WorkspaceUserRole.unknown;
    return WorkspaceUserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceUserRole.unknown,
    );
  }
}

/// User status in workspace
enum WorkspaceUserStatus {
  /// Active user
  active('active'),

  /// Inactive user
  inactive('inactive'),

  /// Pending invitation
  pending('pending'),

  /// Suspended user
  suspended('suspended'),

  /// Unknown status
  unknown('unknown');

  const WorkspaceUserStatus(this.value);
  final String value;

  static WorkspaceUserStatus fromString(String? value) {
    if (value == null) return WorkspaceUserStatus.unknown;
    return WorkspaceUserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceUserStatus.unknown,
    );
  }
}

/// Workspace invitation mode
enum InvitationMode {
  /// Anyone can join
  anyone('anyone'),

  /// Admin approval required
  adminApproval('admin-approval'),

  /// Invite only
  inviteOnly('invite-only'),

  /// Unknown mode
  unknown('unknown');

  const InvitationMode(this.value);
  final String value;

  static InvitationMode fromString(String? value) {
    if (value == null) return InvitationMode.unknown;
    return InvitationMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationMode.unknown,
    );
  }
}

/// Domain referral mode
enum DomainReferralMode {
  /// Do not inform
  doNotInform('do-not-inform'),

  /// Inform user
  inform('inform'),

  /// Unknown mode
  unknown('unknown');

  const DomainReferralMode(this.value);
  final String value;

  static DomainReferralMode fromString(String? value) {
    if (value == null) return DomainReferralMode.unknown;
    return DomainReferralMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DomainReferralMode.unknown,
    );
  }
}

/// Phone type
enum WorkspacePhoneType {
  /// Voicemail
  voicemail('voicemail'),

  /// SMS
  sms('sms'),

  /// Call forwarding
  forwarding('forwarding'),

  /// Unknown type
  unknown('unknown');

  const WorkspacePhoneType(this.value);
  final String value;

  static WorkspacePhoneType fromString(String? value) {
    if (value == null) return WorkspacePhoneType.unknown;
    return WorkspacePhoneType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspacePhoneType.unknown,
    );
  }
}
