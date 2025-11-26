import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Data model for workspace with JSON serialization
class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    super.guid,
    super.description,
  });

  /// Creates a WorkspaceModel from JSON
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String? ?? json['_id'] as String,
      name: json['name'] as String,
      guid: json['guid'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Converts WorkspaceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (guid != null) 'guid': guid,
      if (description != null) 'description': description,
    };
  }

  /// Converts to domain entity
  Workspace toEntity() {
    return Workspace(
      id: id,
      name: name,
      guid: guid,
      description: description,
    );
  }
}
