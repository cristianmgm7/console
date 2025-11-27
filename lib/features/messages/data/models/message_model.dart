import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/timecode.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/transcript.dart';

/// Data model for message with JSON serialization
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.creatorId,
    required super.createdAt,
    required super.workspaceIds,
    required super.channelIds,
    required super.duration,
    required super.audioModels,
    required super.transcripts,
    required super.status,
    required super.type,
    super.lastHeardAt,
    super.heardDuration,
    super.totalHeardDuration,
    super.isTextMessage = false,
    super.notes = '',
    super.lastUpdatedAt,
  });

  /// Creates a MessageModel from DTO
  factory MessageModel.fromDto(MessageDto dto) {
    return MessageModel(
      id: dto.messageId,
      creatorId: dto.creatorId,
      createdAt: dto.createdAt,
      workspaceIds: dto.workspaceIds,
      channelIds: dto.channelIds,
      duration: Duration(milliseconds: dto.durationMs),
      audioModels: dto.audioModels.map((audioDto) => AudioModel(
        id: audioDto.id,
        url: audioDto.url,
        isStreaming: audioDto.streaming,
        language: audioDto.language,
        duration: Duration(milliseconds: audioDto.durationMs),
        waveformData: audioDto.waveformPercentages,
        isOriginal: audioDto.isOriginalAudio,
        format: audioDto.extension,
      )).toList(),
      transcripts: dto.textModels.map((textDto) => Transcript(
        type: textDto.type,
        audioId: textDto.audioId,
        language: textDto.languageId,
        text: textDto.value,
        timecodes: textDto.timecodes.map((timecodeDto) => Timecode(
          text: timecodeDto.text,
          startTime: Duration(milliseconds: timecodeDto.start),
          endTime: Duration(milliseconds: timecodeDto.end),
        )).toList(),
      )).toList(),
      status: dto.status,
      type: dto.type,
      lastHeardAt: dto.lastHeardAt,
      heardDuration: Duration(milliseconds: dto.heardMs),
      totalHeardDuration: Duration(milliseconds: dto.totalHeardMs),
      isTextMessage: dto.isTextMessage,
      notes: dto.notes,
      lastUpdatedAt: dto.lastUpdatedAt,
    );
  }

  /// Creates a MessageModel from normalized JSON (legacy support)
  /// Expects JSON already normalized by JsonNormalizer at data source boundary
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw FormatException('Message JSON missing required id field: $json');
    }

    final creatorId = json['creatorId'] as String? ?? json['userId'] as String?;
    if (creatorId == null) {
      throw FormatException('Message JSON missing required creatorId/userId field: $json');
    }

    final workspaceIds = (json['workspaceIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
                        [json['conversationId'] as String? ?? 'default'];
    final channelIds = (json['channelIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
                      [json['conversationId'] as String? ?? 'default'];

    return MessageModel(
      id: id,
      creatorId: creatorId,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      workspaceIds: workspaceIds,
      channelIds: channelIds,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : Duration.zero,
      audioModels: json['audioUrl'] != null ? [
        AudioModel(
          id: '${id}_audio',
          url: json['audioUrl'] as String,
          isStreaming: false,
          language: 'english',
          duration: json['duration'] != null
              ? Duration(seconds: json['duration'] as int)
              : Duration.zero,
          waveformData: const [],
          isOriginal: true,
          format: 'mp3',
        ),
      ] : [],
      transcripts: json['transcript'] != null ? [
        Transcript(
          type: 'transcript',
          audioId: '${id}_audio',
          language: 'english',
          text: json['transcript'] as String,
          timecodes: [],
        )
      ] : [],
      status: json['status'] as String? ?? 'active',
      type: json['type'] as String? ?? 'channel',
      lastHeardAt: json['lastHeardAt'] != null
          ? DateTime.parse(json['lastHeardAt'] as String)
          : null,
      heardDuration: json['heardDuration'] != null
          ? Duration(seconds: json['heardDuration'] as int)
          : null,
      totalHeardDuration: json['totalHeardDuration'] != null
          ? Duration(seconds: json['totalHeardDuration'] as int)
          : null,
      isTextMessage: json['isTextMessage'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : null,
    );
  }

  /// Converts MessageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'workspaceIds': workspaceIds,
      'channelIds': channelIds,
      'duration': duration.inSeconds,
      'audioModels': audioModels.map((model) => {
        'id': model.id,
        'url': model.url,
        'isStreaming': model.isStreaming,
        'language': model.language,
        'duration': model.duration.inSeconds,
        'waveformData': model.waveformData,
        'isOriginal': model.isOriginal,
        'format': model.format,
      },).toList(),
      'transcripts': transcripts.map((transcript) => {
        'type': transcript.type,
        'audioId': transcript.audioId,
        'language': transcript.language,
        'text': transcript.text,
        'timecodes': transcript.timecodes.map((timecode) => {
          'text': timecode.text,
          'startTime': timecode.startTime.inMilliseconds,
          'endTime': timecode.endTime.inMilliseconds,
        },).toList(),
      },).toList(),
      'status': status,
      'type': type,
      if (lastHeardAt != null) 'lastHeardAt': lastHeardAt!.toIso8601String(),
      if (heardDuration != null) 'heardDuration': heardDuration!.inSeconds,
      if (totalHeardDuration != null) 'totalHeardDuration': totalHeardDuration!.inSeconds,
      'isTextMessage': isTextMessage,
      'notes': notes,
      if (lastUpdatedAt != null) 'lastUpdatedAt': lastUpdatedAt!.toIso8601String(),
    };
  }

  /// Converts to domain entity
  Message toEntity() => this;
}
