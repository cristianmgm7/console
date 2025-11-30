import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Data model for workspace with JSON serialization
class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    super.guid,
    super.description,
  });

  /// Creates a WorkspaceModel from normalized JSON
  /// Expects JSON already normalized by JsonNormalizer at data source boundary
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw FormatException('Workspace JSON missing required id field: $json');
    }

    return WorkspaceModel(
      id: id,
      name: json['name'] as String? ?? 'Unknown Workspace',
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
