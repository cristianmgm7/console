import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// UI model for message presentation
/// Contains computed properties for presentation layer
class MessageUiModel extends Equatable {
  const MessageUiModel({
    required this.id,
    required this.creatorId,
    required this.createdAt,
    required this.workspaceIds,
    required this.channelIds,
    required this.duration,
    required this.audioModels,
    required this.textModels,
    required this.status,
    required this.type,
    required this.lastHeardAt,
    required this.heardDuration,
    required this.totalHeardDuration,
    required this.isTextMessage,
    required this.notes,
    required this.lastUpdatedAt,
    required this.parentMessageId,
    // Computed properties for UI
    required this.conversationId,
    required this.userId,
    required this.text,
    required this.transcriptText,
    required this.audioUrl,
    // Participant data (replaces User creator)
    this.participant,
  });

  // Original message properties
  final String id;
  final String creatorId;
  final DateTime createdAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final Duration duration;
  final List<AudioModel> audioModels;
  final List<TextModel> textModels;
  final String status;
  final String type;
  final DateTime? lastHeardAt;
  final Duration? heardDuration;
  final Duration? totalHeardDuration;
  final bool isTextMessage;
  final String notes;
  final DateTime? lastUpdatedAt;
  final String? parentMessageId;

  // Participant data (replaces User creator)
  final ConversationCollaborator? participant;

  // Computed UI properties
  final String conversationId;
  final String userId;
  final String? text;
  final String? transcriptText;
  final String? audioUrl;

  // Computed properties for creator display
  /// Full name of the message creator
  String? get creatorFullName {
    if (participant == null) return null;
    final firstName = participant!.firstName ?? '';
    final lastName = participant!.lastName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return null;
    return '$firstName $lastName'.trim();
  }

  /// Avatar URL of the message creator
  String? get creatorAvatarUrl => participant?.imageUrl;

  /// Initials for avatar fallback
  String get creatorInitials {
    if (participant == null) return '?';
    final firstName = participant!.firstName ?? '';
    final lastName = participant!.lastName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return '?';
    if (lastName.isEmpty) return firstName[0].toUpperCase();
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  // Computed properties
  /// Whether this message has MP3 audio
  bool get hasPlayableAudio => audioModels.any((audio) => audio.format == 'mp3');

  /// Gets the MP3 audio model if available, null otherwise
  AudioModel? get playableAudioModel => audioModels.firstWhere(
    (audio) => audio.format == 'mp3',
    orElse: () => audioModels.first,
  );

  @override
  List<Object?> get props => [
    id,
    creatorId,
    createdAt,
    workspaceIds,
    channelIds,
    duration,
    audioModels,
    textModels,
    status,
    type,
    lastHeardAt,
    heardDuration,
    totalHeardDuration,
    isTextMessage,
    notes,
    lastUpdatedAt,
    parentMessageId,
    participant,
    conversationId,
    userId,
    text,
    transcriptText,
    audioUrl,
  ];
}
