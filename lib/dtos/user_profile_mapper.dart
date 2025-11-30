import 'package:carbon_voice_console/dtos/user_profile.dart';
import 'package:carbon_voice_console/dtos/user_profile_dto.dart';

/// Mapper extension to convert UserProfileDto to UserProfile domain model
extension UserProfileMapper on UserProfileDto {
  UserProfile toDomain(String userId) {
    // Use the userId from the URL parameter as the ID, since the API response might not include it
    final validatedId = id ?? userId;

    // Extract key permissions
    final canViewMembers = permissions?['view-members-workspace']?.value ?? false;
    final canDeleteMessages = permissions?['can-delete-sent-messages-workspace']?.value ?? false;
    final canForwardMessages = permissions?['can-forward-messages-workspace']?.value ?? false;

    // Check if user has workspaces
    final hasWorkspaces = workspaces?.isNotEmpty ?? false;

    return UserProfile(
      id: validatedId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      canViewMembers: canViewMembers,
      canDeleteMessages: canDeleteMessages,
      canForwardMessages: canForwardMessages,
      hasWorkspaces: hasWorkspaces,
    );
  }
}
