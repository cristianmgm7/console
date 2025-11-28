/// Domain model for User Profile with only significant parameters
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.canViewMembers = false,
    this.canDeleteMessages = false,
    this.canForwardMessages = false,
    this.hasWorkspaces = false,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;

  // Key permissions
  final bool canViewMembers;
  final bool canDeleteMessages;
  final bool canForwardMessages;

  // Derived data
  final bool hasWorkspaces;

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
    bool? canViewMembers,
    bool? canDeleteMessages,
    bool? canForwardMessages,
    bool? hasWorkspaces,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      canViewMembers: canViewMembers ?? this.canViewMembers,
      canDeleteMessages: canDeleteMessages ?? this.canDeleteMessages,
      canForwardMessages: canForwardMessages ?? this.canForwardMessages,
      hasWorkspaces: hasWorkspaces ?? this.hasWorkspaces,
    );
  }
}
