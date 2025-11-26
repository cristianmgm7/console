import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
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
  /// Uses JsonNormalizer to handle API field name variations
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final normalized = JsonNormalizer.normalizeWorkspace(json);
    
    final id = normalized['id'] as String?;
    if (id == null) {
      throw FormatException('Workspace JSON missing required id field: $json');
    }

    return WorkspaceModel(
      id: id,
      name: normalized['name'] as String? ?? 'Unknown Workspace',
      guid: normalized['guid'] as String?,
      description: normalized['description'] as String?,
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
