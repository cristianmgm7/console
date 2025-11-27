import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/reaction_summary_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/utm_data_dto.dart';

/// DTO for message from API response
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

  final DateTime? deletedAt;
  final String? parentMessageId;
  final int heardMs;
  final UtmDataDto utmData;
  final String? name;
  final String? sourceMessageId;
  final String messageId;
  final String creatorId;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final int durationMs;
  final List<dynamic> attachments;
  final String notes;
  final bool notify;
  final DateTime lastHeardUpdate;
  final ReactionSummaryDto reactionSummary;
  final bool isTextMessage;
  final String status;
  final List<String> labelIds;
  final List<AudioModelDto> audioModels;
  final List<TextModelDto> textModels;
  final String cacheKey;
  final String audioDelivery;
  final int notifiedUsers;
  final int totalHeardMs;
  final String usersCaughtUp;
  final String? forwardId;
  final String? shareLinkId;
  final int socketDisconnectsWhileStreaming;
  final String? streamKey;
  final String type;
  final int channelSequence;
  final DateTime lastHeardAt;
  final String? folderId;

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      parentMessageId: json['parent_message_id'] as String?,
      heardMs: (json['heard_ms'] as num?)?.toInt() ?? 0,
      utmData: json['utm_data'] != null
          ? UtmDataDto.fromJson(json['utm_data'] as Map<String, dynamic>)
          : const UtmDataDto(),
      name: json['name'] as String?,
      sourceMessageId: json['source_message_id'] as String?,
      messageId: json['message_id'] as String,
      creatorId: json['creator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
      workspaceIds: (json['workspace_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      channelIds: (json['channel_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      attachments: json['attachments'] as List<dynamic>? ?? [],
      notes: json['notes'] as String,
      notify: json['notify'] as bool,
      lastHeardUpdate: DateTime.parse(json['last_heard_update'] as String),
      reactionSummary: json['reaction_summary'] != null
          ? ReactionSummaryDto.fromJson(json['reaction_summary'] as Map<String, dynamic>)
          : const ReactionSummaryDto(reactionCounts: {}, topUserReactions: []),
      isTextMessage: json['is_text_message'] as bool,
      status: json['status'] as String,
      labelIds: (json['label_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      audioModels: (json['audio_models'] as List<dynamic>?)
          ?.map((e) => AudioModelDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      textModels: (json['text_models'] as List<dynamic>?)
          ?.map((e) => TextModelDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      cacheKey: json['cache_key'] as String,
      audioDelivery: json['audio_delivery'] as String,
      notifiedUsers: (json['notified_users'] as num?)?.toInt() ?? 0,
      totalHeardMs: (json['total_heard_ms'] as num?)?.toInt() ?? 0,
      usersCaughtUp: json['users_caught_up'] as String,
      forwardId: json['forward_id'] as String?,
      shareLinkId: json['share_link_id'] as String?,
      socketDisconnectsWhileStreaming:
          (json['socket_disconnects_while_streaming'] as num?)?.toInt() ?? 0,
      streamKey: json['stream_key'] as String?,
      type: json['type'] as String,
      channelSequence: (json['channel_sequence'] as num?)?.toInt() ?? 0,
      lastHeardAt: DateTime.parse(json['last_heard_at'] as String),
      folderId: json['folder_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      if (parentMessageId != null) 'parent_message_id': parentMessageId,
      'heard_ms': heardMs,
      'utm_data': utmData.toJson(),
      if (name != null) 'name': name,
      if (sourceMessageId != null) 'source_message_id': sourceMessageId,
      'message_id': messageId,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'workspace_ids': workspaceIds,
      'channel_ids': channelIds,
      'duration_ms': durationMs,
      'attachments': attachments,
      'notes': notes,
      'notify': notify,
      'last_heard_update': lastHeardUpdate.toIso8601String(),
      'reaction_summary': reactionSummary.toJson(),
      'is_text_message': isTextMessage,
      'status': status,
      'label_ids': labelIds,
      'audio_models': audioModels.map((e) => e.toJson()).toList(),
      'text_models': textModels.map((e) => e.toJson()).toList(),
      'cache_key': cacheKey,
      'audio_delivery': audioDelivery,
      'notified_users': notifiedUsers,
      'total_heard_ms': totalHeardMs,
      'users_caught_up': usersCaughtUp,
      if (forwardId != null) 'forward_id': forwardId,
      if (shareLinkId != null) 'share_link_id': shareLinkId,
      'socket_disconnects_while_streaming': socketDisconnectsWhileStreaming,
      if (streamKey != null) 'stream_key': streamKey,
      'type': type,
      'channel_sequence': channelSequence,
      'last_heard_at': lastHeardAt.toIso8601String(),
      if (folderId != null) 'folder_id': folderId,
    };
  }
}
