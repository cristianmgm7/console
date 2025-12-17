import 'package:json_annotation/json_annotation.dart';

part 'conversation_dto.g.dart';

// Custom converters for handling complex nested objects
class CollaboratorListConverter
    implements JsonConverter<List<ConversationCollaboratorDto>, List<dynamic>?> {
  const CollaboratorListConverter();

  @override
  List<ConversationCollaboratorDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationCollaboratorDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationCollaboratorDto> object) =>
      object.map((item) => item.toJson()).toList();
}

class AttachmentListConverter
    implements JsonConverter<List<ConversationAttachmentDto>, List<dynamic>?> {
  const AttachmentListConverter();

  @override
  List<ConversationAttachmentDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationAttachmentDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationAttachmentDto> object) =>
      object.map((item) => item.toJson()).toList();
}

class ChannelSpanListConverter
    implements JsonConverter<List<ConversationChannelSpanDto>, List<dynamic>?> {
  const ChannelSpanListConverter();

  @override
  List<ConversationChannelSpanDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationChannelSpanDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationChannelSpanDto> object) =>
      object.map((item) => item.toJson()).toList();
}

class SummaryListConverter implements JsonConverter<List<ConversationSummaryDto>, List<dynamic>?> {
  const SummaryListConverter();

  @override
  List<ConversationSummaryDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationSummaryDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationSummaryDto> object) =>
      object.map((item) => item.toJson()).toList();
}

class SourceListConverter implements JsonConverter<List<ConversationSourceDto>, List<dynamic>?> {
  const SourceListConverter();

  @override
  List<ConversationSourceDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationSourceDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationSourceDto> object) =>
      object.map((item) => item.toJson()).toList();
}

class UserStatsListConverter
    implements JsonConverter<List<ConversationUserStatsDto>, List<dynamic>?> {
  const UserStatsListConverter();

  @override
  List<ConversationUserStatsDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => ConversationUserStatsDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<ConversationUserStatsDto> object) =>
      object.map((item) => item.toJson()).toList();
}

/// DTO for conversation/channel from API response
@JsonSerializable()
class ConversationDto {
  const ConversationDto({
    this.workspaceGuid,
    this.channelGuid,
    this.channelName,
    this.channelKind,
    this.sourceChannelIds,
    this.channelDescription,
    this.bgRrggbb,
    this.txtRrggbb,
    this.channelSettings,
    this.imageUrl,
    this.isPrivate,
    this.postRule,
    this.dmHash,
    this.lastUpdatedTs,
    this.sortOrder,
    this.createdTs,
    this.deletedAt,
    this.ownerName,
    this.smsPhone,
    this.jsonCollaborators,
    this.joinedTs,
    this.isFavorite,
    this.lastHeardTs,
    this.lastPostedTs,
    this.lastViewedAt,
    this.workspaceName,
    this.workspaceImageUrl,
    this.type,
    this.images,
    this.moreCount,
    this.unreadCnt,
    this.avatars,
    this.createdNew,
    this.settings,
    this.attachments,
    this.channelSpans,
    this.visibility,
    this.totalMessages,
    this.totalDurationMilliseconds,
    this.summaries,
    this.isAsync,
    this.asyncStats,
    this.retentionDays,
    this.engagementPercentage,
    this.maxSequenceNumber,
    this.defaultRole,
    this.sources,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) => _$ConversationDtoFromJson(json);

  @JsonKey(name: 'workspace_guid')
  final String? workspaceGuid;

  @JsonKey(name: 'channel_guid')
  final String? channelGuid;

  @JsonKey(name: 'channel_name')
  final String? channelName;

  @JsonKey(name: 'channel_kind')
  final String? channelKind;

  @JsonKey(name: 'source_channel_ids')
  final List<String>? sourceChannelIds;

  @JsonKey(name: 'channel_description')
  final String? channelDescription;

  @JsonKey(name: 'bg_rrggbb')
  final String? bgRrggbb;

  @JsonKey(name: 'txt_rrggbb')
  final String? txtRrggbb;

  @JsonKey(name: 'channel_settings')
  final String? channelSettings;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'is_private')
  final String? isPrivate;

  @JsonKey(name: 'post_rule')
  final String? postRule;

  @JsonKey(name: 'dm_hash')
  final String? dmHash;

  @JsonKey(name: 'last_updated_ts')
  final int? lastUpdatedTs;

  @JsonKey(name: 'sort_order')
  final String? sortOrder;

  @JsonKey(name: 'created_ts')
  final int? createdTs;

  @JsonKey(name: 'deleted_at')
  final int? deletedAt;

  @JsonKey(name: 'owner_name')
  final String? ownerName;

  @JsonKey(name: 'sms_phone')
  final String? smsPhone;

  @CollaboratorListConverter()
  @JsonKey(name: 'json_collaborators')
  final List<ConversationCollaboratorDto>? jsonCollaborators;

  @JsonKey(name: 'joined_ts')
  final int? joinedTs;

  @JsonKey(name: 'is_favorite')
  final String? isFavorite;

  @JsonKey(name: 'last_heard_ts')
  final int? lastHeardTs;

  @JsonKey(name: 'last_posted_ts')
  final int? lastPostedTs;

  @JsonKey(name: 'last_viewed_at')
  final String? lastViewedAt;

  @JsonKey(name: 'workspace_name')
  final String? workspaceName;

  @JsonKey(name: 'workspace_image_url')
  final String? workspaceImageUrl;

  final String? type;
  final List<String>? images;

  @JsonKey(name: 'moreCount')
  final int? moreCount;

  @JsonKey(name: 'unread_cnt')
  final int? unreadCnt;

  final ConversationAvatarsDto? avatars;

  @JsonKey(name: 'createdNew')
  final bool? createdNew;

  final Map<String, dynamic>? settings;

  @AttachmentListConverter()
  final List<ConversationAttachmentDto>? attachments;

  @ChannelSpanListConverter()
  @JsonKey(name: 'channel_spans')
  final List<ConversationChannelSpanDto>? channelSpans;

  final String? visibility;

  @JsonKey(name: 'total_messages')
  final int? totalMessages;

  @JsonKey(name: 'total_duration_milliseconds')
  final int? totalDurationMilliseconds;

  @SummaryListConverter()
  final List<ConversationSummaryDto>? summaries;

  @JsonKey(name: 'is_async')
  final bool? isAsync;

  @JsonKey(name: 'async_stats')
  final ConversationAsyncStatsDto? asyncStats;

  @JsonKey(name: 'retention_days')
  final int? retentionDays;

  @JsonKey(name: 'engagement_percentage')
  final int? engagementPercentage;

  @JsonKey(name: 'max_sequence_number')
  final int? maxSequenceNumber;

  @JsonKey(name: 'default_role')
  final String? defaultRole;

  @SourceListConverter()
  final List<ConversationSourceDto>? sources;

  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);
}

/// DTO for conversation collaborator
@JsonSerializable()
class ConversationCollaboratorDto {
  const ConversationCollaboratorDto({
    this.userGuid,
    this.imageUrl,
    this.firstName,
    this.lastName,
    this.permission,
    this.joined,
    this.lastPosted,
    this.firstAccessedAt,
    this.lastViewedAt,
    this.status,
    this.primaryLanguage,
  });

  factory ConversationCollaboratorDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationCollaboratorDtoFromJson(json);

  @JsonKey(name: 'user_guid')
  final String? userGuid;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  final String? permission;
  final String? joined;

  @JsonKey(name: 'last_posted')
  final String? lastPosted;

  @JsonKey(name: 'first_accessed_at')
  final String? firstAccessedAt;

  @JsonKey(name: 'last_viewed_at')
  final String? lastViewedAt;

  final String? status;

  @JsonKey(name: 'primary_language')
  final String? primaryLanguage;

  Map<String, dynamic> toJson() => _$ConversationCollaboratorDtoToJson(this);
}

/// DTO for conversation avatars
@JsonSerializable()
class ConversationAvatarsDto {
  const ConversationAvatarsDto({
    this.avatars,
    this.numRows,
    this.numColumns,
  });

  factory ConversationAvatarsDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationAvatarsDtoFromJson(json);

  final List<ConversationAvatarDto>? avatars;

  @JsonKey(name: 'numRows')
  final int? numRows;

  @JsonKey(name: 'numColumns')
  final int? numColumns;

  Map<String, dynamic> toJson() => _$ConversationAvatarsDtoToJson(this);
}

/// DTO for individual avatar
@JsonSerializable()
class ConversationAvatarDto {
  const ConversationAvatarDto({
    this.children,
    this.type,
    this.imageUrl,
    this.text,
  });

  factory ConversationAvatarDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationAvatarDtoFromJson(json);

  final List<ConversationAvatarDto>? children;
  final String? type;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final String? text;

  Map<String, dynamic> toJson() => _$ConversationAvatarDtoToJson(this);
}

/// DTO for conversation attachment
@JsonSerializable()
class ConversationAttachmentDto {
  const ConversationAttachmentDto({
    this.id,
    this.clientId,
    this.creatorId,
    this.createdAt,
    this.type,
    this.link,
    this.activeBegin,
    this.activeEnd,
    this.filename,
    this.mimeType,
    this.lengthInBytes,
    this.location,
  });

  factory ConversationAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationAttachmentDtoFromJson(json);

  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'client_id')
  final String? clientId;

  @JsonKey(name: 'creator_id')
  final String? creatorId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  final String? type;
  final String? link;

  @JsonKey(name: 'active_begin')
  final String? activeBegin;

  @JsonKey(name: 'active_end')
  final String? activeEnd;

  final String? filename;

  @JsonKey(name: 'mime_type')
  final String? mimeType;

  @JsonKey(name: 'length_in_bytes')
  final int? lengthInBytes;

  final ConversationLocationDto? location;

  Map<String, dynamic> toJson() => _$ConversationAttachmentDtoToJson(this);
}

/// DTO for location data
@JsonSerializable()
class ConversationLocationDto {
  const ConversationLocationDto({
    this.latitude,
    this.longitude,
  });

  factory ConversationLocationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationLocationDtoFromJson(json);

  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => _$ConversationLocationDtoToJson(this);
}

/// DTO for channel span
@JsonSerializable()
class ConversationChannelSpanDto {
  const ConversationChannelSpanDto({
    this.id,
    this.begin,
    this.end,
    this.deletedAt,
    this.requiredUsers,
    this.type,
    this.topic,
  });

  factory ConversationChannelSpanDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationChannelSpanDtoFromJson(json);

  final String? id;
  final String? begin;
  final String? end;

  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  @JsonKey(name: 'required_users')
  final List<String>? requiredUsers;

  final String? type;
  final String? topic;

  Map<String, dynamic> toJson() => _$ConversationChannelSpanDtoToJson(this);
}

/// DTO for conversation summary
@JsonSerializable()
class ConversationSummaryDto {
  const ConversationSummaryDto({
    this.channelId,
    this.spanId,
    this.items,
  });

  factory ConversationSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryDtoFromJson(json);

  @JsonKey(name: 'channel_id')
  final String? channelId;

  @JsonKey(name: 'span_id')
  final String? spanId;

  final List<ConversationSummaryItemDto>? items;

  Map<String, dynamic> toJson() => _$ConversationSummaryDtoToJson(this);
}

/// DTO for summary item
@JsonSerializable()
class ConversationSummaryItemDto {
  const ConversationSummaryItemDto({
    this.userId,
    this.text,
    this.type,
  });

  factory ConversationSummaryItemDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryItemDtoFromJson(json);

  @JsonKey(name: 'user_id')
  final String? userId;

  final String? text;
  final String? type;

  Map<String, dynamic> toJson() => _$ConversationSummaryItemDtoToJson(this);
}

/// DTO for async stats
@JsonSerializable()
class ConversationAsyncStatsDto {
  const ConversationAsyncStatsDto({
    this.channelStats,
    this.userStats,
  });

  factory ConversationAsyncStatsDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationAsyncStatsDtoFromJson(json);

  @JsonKey(name: 'channel_stats')
  final ConversationChannelStatsDto? channelStats;

  @JsonKey(name: 'user_stats')
  @UserStatsListConverter()
  final List<ConversationUserStatsDto>? userStats;

  Map<String, dynamic> toJson() => _$ConversationAsyncStatsDtoToJson(this);
}

/// DTO for channel stats
@JsonSerializable()
class ConversationChannelStatsDto {
  const ConversationChannelStatsDto({
    this.totalDurationMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalMessagesPosted,
    this.totalUsers,
  });

  factory ConversationChannelStatsDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationChannelStatsDtoFromJson(json);

  @JsonKey(name: 'total_duration_milliseconds')
  final int? totalDurationMilliseconds;

  @JsonKey(name: 'total_heard_milliseconds')
  final int? totalHeardMilliseconds;

  @JsonKey(name: 'total_engaged_percentage')
  final int? totalEngagedPercentage;

  @JsonKey(name: 'total_messages_posted')
  final int? totalMessagesPosted;

  @JsonKey(name: 'total_users')
  final int? totalUsers;

  Map<String, dynamic> toJson() => _$ConversationChannelStatsDtoToJson(this);
}

/// DTO for user stats
@JsonSerializable()
class ConversationUserStatsDto {
  const ConversationUserStatsDto({
    this.userId,
    this.totalMessagesPosted,
    this.totalSentMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalHeardMessages,
    this.totalUnheardMessages,
  });

  factory ConversationUserStatsDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationUserStatsDtoFromJson(json);

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'total_messages_posted')
  final int? totalMessagesPosted;

  @JsonKey(name: 'total_sent_milliseconds')
  final int? totalSentMilliseconds;

  @JsonKey(name: 'total_heard_milliseconds')
  final int? totalHeardMilliseconds;

  @JsonKey(name: 'total_engaged_percentage')
  final int? totalEngagedPercentage;

  @JsonKey(name: 'total_heard_messages')
  final int? totalHeardMessages;

  @JsonKey(name: 'total_unheard_messages')
  final int? totalUnheardMessages;

  Map<String, dynamic> toJson() => _$ConversationUserStatsDtoToJson(this);
}

/// DTO for source
@JsonSerializable()
class ConversationSourceDto {
  const ConversationSourceDto({
    this.type,
    this.value,
  });

  factory ConversationSourceDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationSourceDtoFromJson(json);

  final String? type;
  final String? value;

  Map<String, dynamic> toJson() => _$ConversationSourceDtoToJson(this);
}
