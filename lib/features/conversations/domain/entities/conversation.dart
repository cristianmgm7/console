import 'package:equatable/equatable.dart';

/// Domain entity representing a conversation (channel)
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.guid,
    this.description,
    this.createdAt,
    this.messageCount,
    this.colorIndex, // For UI color assignment (0-based index)
  });

  final String id;
  final String name;
  final String workspaceId;
  final String? guid;
  final String? description;
  final DateTime? createdAt;
  final int? messageCount;
  final int? colorIndex; // Assigned by repository for consistent coloring

  @override
  List<Object?> get props => [id, name, workspaceId, guid, description, createdAt, messageCount, colorIndex];
}

