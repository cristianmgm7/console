import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Data model for conversation with JSON serialization
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.name,
    required super.workspaceId,
    super.guid,
    super.description,
    super.createdAt,
    super.messageCount,
    super.colorIndex, // Pass through color index
  });

  /// Creates a ConversationModel from JSON
  /// Uses JsonNormalizer to handle API field name variations
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final normalized = JsonNormalizer.normalizeConversation(json);
    
    final id = normalized['id'] as String?;
    if (id == null) {
      throw FormatException('Conversation JSON missing required id field: $json');
    }

    final workspaceId = normalized['workspaceId'] as String?;
    if (workspaceId == null) {
      throw FormatException('Conversation JSON missing required workspaceId field: $json');
    }

    return ConversationModel(
      id: id,
      name: normalized['name'] as String? ?? 'Unknown Conversation',
      workspaceId: workspaceId,
      guid: normalized['guid'] as String?,
      description: normalized['description'] as String?,
      createdAt: normalized['createdAt'] != null
          ? DateTime.parse(normalized['createdAt'] as String)
          : null,
      messageCount: normalized['messageCount'] as int?,
    );
  }

  /// Converts ConversationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspaceId': workspaceId,
      if (guid != null) 'guid': guid,
      if (description != null) 'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (messageCount != null) 'messageCount': messageCount,
    };
  }

  /// Converts to domain entity
  Conversation toEntity({int? assignedColorIndex}) {
    return Conversation(
      id: id,
      name: name,
      workspaceId: workspaceId,
      guid: guid,
      description: description,
      createdAt: createdAt,
      messageCount: messageCount,
      colorIndex: assignedColorIndex ?? colorIndex, // Use assigned color or existing
    );
  }
}
