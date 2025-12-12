import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension ConversationUiMapper on Conversation {
  /// Creates a UI model from the conversation entity
  ConversationUiModel toUiModel() {
    return ConversationUiModel(
      id: guid ?? channelGuid,
      name: channelName ?? 'Unknown Conversation',
      description: description ?? channelDescription ?? '',
      coverImageUrl: imageUrl,
      participants: _mapParticipants(),
      totalMessages: totalMessages ?? 0,
      totalDuration: Duration(milliseconds: totalDurationMilliseconds ?? 0),
      createdAt: createdAt,
      updatedAt: lastUpdatedTs != null ? DateTime.fromMillisecondsSinceEpoch(lastUpdatedTs!) : null,
    );
  }

  /// Maps conversation collaborators to UI participants
  List<ConversationParticipantUiModel> _mapParticipants() {
    if (collaborators == null || collaborators!.isEmpty) {
      return [];
    }

    return collaborators!.map((collaborator) {
      final firstName = collaborator.firstName ?? '';
      final lastName = collaborator.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Use userGuid as ID, fallback to a generated one
      final participantId = collaborator.userGuid ?? 'user_${collaborators!.indexOf(collaborator)}';

      // Determine role from permission or default to 'member'
      final role = _mapPermissionToRole(collaborator.permission);

      // Parse last posted time if available
      DateTime? lastActiveAt;
      if (collaborator.lastPosted != null) {
        try {
          lastActiveAt = DateTime.fromMillisecondsSinceEpoch(int.parse(collaborator.lastPosted!));
        } catch (_) {
          // Ignore parsing errors
        }
      }

      return ConversationParticipantUiModel(
        id: participantId,
        fullName: fullName.isEmpty ? participantId : fullName,
        avatarUrl: collaborator.imageUrl,
        role: role,
        permissions: collaborator.permission,
        lastActiveAt: lastActiveAt,
      );
    }).toList();
  }

  /// Maps permission string to user-friendly role name
  String? _mapPermissionToRole(String? permission) {
    if (permission == null) return null;

    switch (permission.toLowerCase()) {
      case 'owner':
      case 'admin':
        return 'Admin';
      case 'editor':
      case 'write':
        return 'Editor';
      case 'viewer':
      case 'read':
        return 'Viewer';
      case 'member':
      default:
        return 'Member';
    }
  }
}
