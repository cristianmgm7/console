import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/reaction_summary_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/utm_data_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_dto.g.dart';

// Custom converter for UtmDataDto that handles null values
class UtmDataDtoConverter implements JsonConverter<UtmDataDto, Map<String, dynamic>?> {
  const UtmDataDtoConverter();

  @override
  UtmDataDto fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UtmDataDto();
    return UtmDataDto.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(UtmDataDto object) => object.toJson();
}

// Custom converter for ReactionSummaryDto that handles null values
class ReactionSummaryDtoConverter implements JsonConverter<ReactionSummaryDto, Map<String, dynamic>?> {
  const ReactionSummaryDtoConverter();

  @override
  ReactionSummaryDto fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReactionSummaryDto();
    return ReactionSummaryDto.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(ReactionSummaryDto object) => object.toJson();
}

/// DTO for message from API response
@JsonSerializable()
class MessageDto {
  const MessageDto({
    required this.reactionSummary,
    required this.utmData,
    this.creatorId,
    this.createdAt,
    this.messageId,
    this.lastUpdatedAt,
    this.workspaceIds,
    this.channelIds,
    this.attachments,
    this.notes,
    this.notify,
    this.lastHeardUpdate,
    this.isTextMessage,
    this.status,
    this.labelIds,
    this.audioModels,
    this.textModels,
    this.cacheKey,
    this.audioDelivery,
    this.usersCaughtUp,
    this.type,
    this.lastHeardAt,
    this.heardMs,
    this.durationMs,
    this.notifiedUsers,
    this.totalHeardMs,
    this.socketDisconnectsWhileStreaming,
    this.channelSequence,
    this.deletedAt,
    this.parentMessageId,
    this.name,
    this.sourceMessageId,
    this.forwardId,
    this.shareLinkId,
    this.streamKey,
    this.folderId,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) => _$MessageDtoFromJson(json);

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @JsonKey(name: 'parent_message_id')
  final String? parentMessageId;

  @JsonKey(name: 'heard_ms')
  final int? heardMs;

  @UtmDataDtoConverter()
  @JsonKey(name: 'utm_data')
  final UtmDataDto utmData;

  final String? name;

  @JsonKey(name: 'source_message_id')
  final String? sourceMessageId;

  @JsonKey(name: 'message_id')
  final String? messageId;

  @JsonKey(name: 'creator_id')
  final String? creatorId;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime? lastUpdatedAt;

  @JsonKey(name: 'workspace_ids')
  final List<String>? workspaceIds;

  @JsonKey(name: 'channel_ids')
  final List<String>? channelIds;

  @JsonKey(name: 'duration_ms')
  final int? durationMs;

  final List<dynamic>? attachments;
  final String? notes;
  final bool? notify;

  @JsonKey(name: 'last_heard_update')
  final DateTime? lastHeardUpdate;

  @ReactionSummaryDtoConverter()
  @JsonKey(name: 'reaction_summary')
  final ReactionSummaryDto reactionSummary;

  @JsonKey(name: 'is_text_message')
  final bool? isTextMessage;

  final String? status;

  @JsonKey(name: 'label_ids')
  final List<String>? labelIds;

  @JsonKey(name: 'audio_models')
  final List<AudioModelDto>? audioModels;

  @JsonKey(name: 'text_models')
  final List<TextModelDto>? textModels;

  @JsonKey(name: 'cache_key')
  final String? cacheKey;

  @JsonKey(name: 'audio_delivery')
  final String? audioDelivery;

  @JsonKey(name: 'notified_users')
  final int? notifiedUsers;

  @JsonKey(name: 'total_heard_ms')
  final int? totalHeardMs;

  @JsonKey(name: 'users_caught_up')
  final String? usersCaughtUp;

  @JsonKey(name: 'forward_id')
  final String? forwardId;

  @JsonKey(name: 'share_link_id')
  final String? shareLinkId;

  @JsonKey(name: 'socket_disconnects_while_streaming')
  final int? socketDisconnectsWhileStreaming;

  @JsonKey(name: 'stream_key')
  final String? streamKey;

  final String? type;

  @JsonKey(name: 'channel_sequence')
  final int? channelSequence;

  @JsonKey(name: 'last_heard_at')
  final DateTime? lastHeardAt;

  @JsonKey(name: 'folder_id')
  final String? folderId;

  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);
}
