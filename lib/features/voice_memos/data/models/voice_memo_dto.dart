import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_memo_dto.g.dart';

/// DTO that mirrors the exact JSON structure from the voice memo API
@JsonSerializable()
class VoiceMemoDto {
  const VoiceMemoDto({
    this.messageId,
    this.creatorId,
    this.createdAt,
    this.deletedAt,
    this.lastUpdatedAt,
    this.workspaceIds,
    this.channelIds,
    this.parentMessageId,
    this.heardMs,
    this.notes,
    this.name,
    this.isTextMessage,
    this.status,
    this.type,
    this.audioModels,
    this.textModels,
    this.folderId,
    this.lastHeardAt,
    this.totalHeardMs,
    this.durationMs,
  });

  factory VoiceMemoDto.fromJson(Map<String, dynamic> json) => _$VoiceMemoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMemoDtoToJson(this);

  @JsonKey(name: 'message_id')
  final String? messageId;

  @JsonKey(name: 'creator_id')
  final String? creatorId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  @JsonKey(name: 'last_updated_at')
  final String? lastUpdatedAt;

  @JsonKey(name: 'workspace_ids')
  final List<String>? workspaceIds;

  @JsonKey(name: 'channel_ids')
  final List<String>? channelIds;

  @JsonKey(name: 'parent_message_id')
  final String? parentMessageId;

  @JsonKey(name: 'heard_ms')
  final int? heardMs;

  final String? notes;
  final String? name;

  @JsonKey(name: 'is_text_message')
  final bool? isTextMessage;

  final String? status;
  final String? type;

  @JsonKey(name: 'audio_models')
  final List<AudioModelDto>? audioModels; // Reuses existing AudioModelDto from messages

  @JsonKey(name: 'text_models')
  final List<TextModelDto>? textModels; // Reuses existing TextModelDto from messages

  @JsonKey(name: 'folder_id')
  final String? folderId;

  @JsonKey(name: 'last_heard_at')
  final String? lastHeardAt;

  @JsonKey(name: 'total_heard_ms')
  final int? totalHeardMs;

  @JsonKey(name: 'duration_ms')
  final int? durationMs;
}
