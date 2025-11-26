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
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? json['_id'] as String,
      name: json['name'] as String,
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String,
      guid: json['guid'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      messageCount: json['messageCount'] as int? ?? json['message_count'] as int?,
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
