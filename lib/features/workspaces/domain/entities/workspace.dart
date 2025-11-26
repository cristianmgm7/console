import 'package:equatable/equatable.dart';

/// Domain entity representing a workspace
class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    this.guid,
    this.description,
  });

  final String id;
  final String name;
  final String? guid;
  final String? description;

  @override
  List<Object?> get props => [id, name, guid, description];
}


