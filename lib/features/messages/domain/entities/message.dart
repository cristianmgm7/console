import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing a message
class Message extends Equatable {
  const Message({
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
    this.lastHeardAt,
    this.heardDuration,
    this.totalHeardDuration,
    this.isTextMessage = false,
    this.notes = '',
    this.lastUpdatedAt,
    this.parentMessageId,
  });

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

  // Domain-level computed properties (simple aliases)
  String get conversationId => channelIds.isNotEmpty ? channelIds.first : '';
  String get userId => creatorId;

  // Audio-related computed properties
  /// Whether this message has audio that can be downloaded
  bool get hasDownloadableAudio => audioModels.any((audio) => audio.presignedUrl != null && audio.presignedUrl!.isNotEmpty);

  /// Gets the first downloadable audio model, null if none available
  AudioModel? get downloadableAudioModel {
    if (!hasDownloadableAudio) return null;
    return audioModels.firstWhere(
      (audio) => audio.presignedUrl != null && audio.presignedUrl!.isNotEmpty,
    );
  }

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
      ];
}
