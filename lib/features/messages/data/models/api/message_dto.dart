import 'package:json_annotation/json_annotation.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/reaction_summary_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/utm_data_dto.dart';

part 'message_dto.g.dart';

/// DTO for message from API response
@JsonSerializable()
class MessageDto {
  const MessageDto({
    required this.heardMs,
    required this.utmData,
    required this.messageId,
    required this.creatorId,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.workspaceIds,
    required this.channelIds,
    required this.durationMs,
    required this.attachments,
    required this.notes,
    required this.notify,
    required this.lastHeardUpdate,
    required this.reactionSummary,
    required this.isTextMessage,
    required this.status,
    required this.labelIds,
    required this.audioModels,
    required this.textModels,
    required this.cacheKey,
    required this.audioDelivery,
    required this.notifiedUsers,
    required this.totalHeardMs,
    required this.usersCaughtUp,
    required this.socketDisconnectsWhileStreaming,
    required this.type,
    required this.channelSequence,
    required this.lastHeardAt,
    this.deletedAt,
    this.parentMessageId,
    this.name,
    this.sourceMessageId,
    this.forwardId,
    this.shareLinkId,
    this.streamKey,
    this.folderId,
  });

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @JsonKey(name: 'parent_message_id')
  final String? parentMessageId;

  @JsonKey(name: 'heard_ms')
  final int heardMs;

  @JsonKey(name: 'utm_data')
  final UtmDataDto utmData;

  final String? name;

  @JsonKey(name: 'source_message_id')
  final String? sourceMessageId;

  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'creator_id')
  final String creatorId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime lastUpdatedAt;

  @JsonKey(name: 'workspace_ids')
  final List<String> workspaceIds;

  @JsonKey(name: 'channel_ids')
  final List<String> channelIds;

  @JsonKey(name: 'duration_ms')
  final int durationMs;

  final List<dynamic> attachments;
  final String notes;
  final bool notify;

  @JsonKey(name: 'last_heard_update')
  final DateTime lastHeardUpdate;

  @JsonKey(name: 'reaction_summary')
  final ReactionSummaryDto reactionSummary;

  @JsonKey(name: 'is_text_message')
  final bool isTextMessage;

  final String status;

  @JsonKey(name: 'label_ids')
  final List<String> labelIds;

  @JsonKey(name: 'audio_models')
  final List<AudioModelDto> audioModels;

  @JsonKey(name: 'text_models')
  final List<TextModelDto> textModels;

  @JsonKey(name: 'cache_key')
  final String cacheKey;

  @JsonKey(name: 'audio_delivery')
  final String audioDelivery;

  @JsonKey(name: 'notified_users')
  final int notifiedUsers;

  @JsonKey(name: 'total_heard_ms')
  final int totalHeardMs;

  @JsonKey(name: 'users_caught_up')
  final String usersCaughtUp;

  @JsonKey(name: 'forward_id')
  final String? forwardId;

  @JsonKey(name: 'share_link_id')
  final String? shareLinkId;

  @JsonKey(name: 'socket_disconnects_while_streaming')
  final int socketDisconnectsWhileStreaming;

  @JsonKey(name: 'stream_key')
  final String? streamKey;

  final String type;

  @JsonKey(name: 'channel_sequence')
  final int channelSequence;

  @JsonKey(name: 'last_heard_at')
  final DateTime lastHeardAt;

  @JsonKey(name: 'folder_id')
  final String? folderId;

  factory MessageDto.fromJson(Map<String, dynamic> json) => _$MessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);
}
