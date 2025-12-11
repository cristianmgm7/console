import 'package:equatable/equatable.dart';

/// UI model for preview visualization
/// Contains all display-ready data for the preview screen
class PreviewUiModel extends Equatable {
  const PreviewUiModel({
    required this.conversationName,
    required this.conversationDescription,
    required this.conversationCoverUrl,
    required this.participants,
    required this.messageCount,
    required this.totalDuration,
    required this.totalDurationFormatted,
    required this.messages,
  });

  // Conversation metadata
  final String conversationName;
  final String conversationDescription;
  final String? conversationCoverUrl;

  // Participants
  final List<PreviewParticipant> participants;

  // Message statistics
  final int messageCount;
  final Duration totalDuration;
  final String totalDurationFormatted; // MM:SS format

  // Selected messages with creator info
  final List<PreviewMessage> messages;

  @override
  List<Object?> get props => [
    conversationName,
    conversationDescription,
    conversationCoverUrl,
    participants,
    messageCount,
    totalDuration,
    totalDurationFormatted,
    messages,
  ];
}

/// Participant in the conversation
class PreviewParticipant extends Equatable {
  const PreviewParticipant({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, fullName, avatarUrl];
}

/// Message for preview display
class PreviewMessage extends Equatable {
  const PreviewMessage({
    required this.id,
    required this.creatorName,
    required this.createdAt,
    required this.createdAtFormatted,
    required this.duration,
    required this.durationFormatted,
    this.creatorAvatarUrl,
    this.summary,
    this.audioUrl,
  });

  final String id;
  final String creatorName;
  final String? creatorAvatarUrl;
  final DateTime createdAt;
  final String createdAtFormatted; // e.g., "12/11/25 2:30 PM"
  final Duration duration;
  final String durationFormatted; // MM:SS format
  final String? summary;
  final String? audioUrl;

  @override
  List<Object?> get props => [
    id,
    creatorName,
    creatorAvatarUrl,
    createdAt,
    createdAtFormatted,
    duration,
    durationFormatted,
    summary,
    audioUrl,
  ];
}
