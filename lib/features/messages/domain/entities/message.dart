import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/transcript.dart';
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
    required this.transcripts,
    required this.status,
    required this.type,
    this.lastHeardAt,
    this.heardDuration,
    this.totalHeardDuration,
    this.isTextMessage = false,
    this.notes = '',
    this.lastUpdatedAt,
  });

  final String id;
  final String creatorId;
  final DateTime createdAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final Duration duration;
  final List<AudioModel> audioModels;
  final List<Transcript> transcripts;
  final String status;
  final String type;
  final DateTime? lastHeardAt;
  final Duration? heardDuration;
  final Duration? totalHeardDuration;
  final bool isTextMessage;
  final String notes;
  final DateTime? lastUpdatedAt;

  // Computed properties
  String get primaryWorkspaceId => workspaceIds.first;
  String get primaryChannelId => channelIds.first;
  AudioModel? get streamingAudioModel =>
      audioModels.where((model) => model.isStreaming).firstOrNull;
  AudioModel? get originalAudioModel =>
      audioModels.where((model) => model.isOriginal).firstOrNull;
  Transcript? get transcriptWithTimecodes =>
      transcripts.where((t) => t.timecodes.isNotEmpty).firstOrNull;
  Transcript? get summaryTranscript =>
      transcripts.where((t) => t.type == 'summary').firstOrNull;

  // Backward compatibility getters
  String get conversationId => primaryChannelId;
  String get userId => creatorId;
  String? get text => notes.isNotEmpty ? notes : null;
  String? get transcript => transcripts.isNotEmpty ? transcripts.first.text : null;
  String? get audioUrl => audioModels.isNotEmpty ? audioModels.first.url : null;
  Map<String, dynamic>? get metadata => {
    'type': type,
    'status': status,
    'isTextMessage': isTextMessage,
    'workspaceIds': workspaceIds,
    'channelIds': channelIds,
    'heardDuration': heardDuration?.inMilliseconds,
    'totalHeardDuration': totalHeardDuration?.inMilliseconds,
    'lastHeardAt': lastHeardAt?.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    'audioModelCount': audioModels.length,
    'transcriptCount': transcripts.length,
  };

  @override
  List<Object?> get props => [
        id,
        creatorId,
        createdAt,
        workspaceIds,
        channelIds,
        duration,
        audioModels,
        transcripts,
        status,
        type,
        lastHeardAt,
        heardDuration,
        totalHeardDuration,
        isTextMessage,
        notes,
        lastUpdatedAt,
      ];
}
