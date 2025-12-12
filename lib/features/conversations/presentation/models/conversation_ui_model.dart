import 'package:equatable/equatable.dart';

/// UI model for conversation presentation
/// Contains formatted data for displaying conversations in the UI
class ConversationUiModel extends Equatable {
  const ConversationUiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.participants,
    required this.totalMessages,
    required this.totalDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final List<ConversationParticipantUiModel> participants;
  final int totalMessages;
  final Duration totalDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Formatted duration string (MM:SS)
  String get totalDurationFormatted {
    final minutes = totalDuration.inMinutes;
    final seconds = totalDuration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Whether this conversation has participants
  bool get hasParticipants => participants.isNotEmpty;

  /// Number of participants
  int get participantCount => participants.length;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    coverImageUrl,
    participants,
    totalMessages,
    totalDuration,
    createdAt,
    updatedAt,
  ];
}

/// UI model for conversation participant
class ConversationParticipantUiModel extends Equatable {
  const ConversationParticipantUiModel({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    this.role,
    this.lastActiveAt,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? role;
  final DateTime? lastActiveAt;

  /// Get initials for avatar fallback
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [id, fullName, avatarUrl, role, lastActiveAt];
}
