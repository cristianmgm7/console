import 'package:equatable/equatable.dart';

/// Domain entity representing a conversation (channel)
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.guid,
    this.description,
    this.createdAt,
    // New fields from API schema
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
    this.collaborators,
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
    this.unreadCount,
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

  final String id;
  final String name;
  final String workspaceId;
  final String? guid;
  final String? description;
  final DateTime? createdAt;

  // New fields from API schema
  final String? workspaceGuid;
  final String? channelGuid;
  final String? channelName;
  final String? channelKind;
  final List<String>? sourceChannelIds;
  final String? channelDescription;
  final String? bgRrggbb;
  final String? txtRrggbb;
  final String? channelSettings;
  final String? imageUrl;
  final String? isPrivate;
  final String? postRule;
  final String? dmHash;
  final int? lastUpdatedTs;
  final String? sortOrder;
  final int? createdTs;
  final int? deletedAt;
  final String? ownerName;
  final String? smsPhone;
  final List<ConversationCollaborator>? collaborators;
  final int? joinedTs;
  final String? isFavorite;
  final int? lastHeardTs;
  final int? lastPostedTs;
  final String? lastViewedAt;
  final String? workspaceName;
  final String? workspaceImageUrl;
  final String? type;
  final List<String>? images;
  final int? moreCount;
  final int? unreadCount;
  final ConversationAvatars? avatars;
  final bool? createdNew;
  final Map<String, dynamic>? settings;
  final List<ConversationAttachment>? attachments;
  final List<ConversationChannelSpan>? channelSpans;
  final String? visibility;
  final int? totalMessages;
  final int? totalDurationMilliseconds;
  final List<ConversationSummary>? summaries;
  final bool? isAsync;
  final ConversationAsyncStats? asyncStats;
  final int? retentionDays;
  final int? engagementPercentage;
  final int? maxSequenceNumber;
  final String? defaultRole;
  final List<ConversationSource>? sources;

  @override
  List<Object?> get props => [
        id,
        name,
        workspaceId,
        guid,
        description,
        createdAt,
        workspaceGuid,
        channelGuid,
        channelName,
        channelKind,
        sourceChannelIds,
        channelDescription,
        bgRrggbb,
        txtRrggbb,
        channelSettings,
        imageUrl,
        isPrivate,
        postRule,
        dmHash,
        lastUpdatedTs,
        sortOrder,
        createdTs,
        deletedAt,
        ownerName,
        smsPhone,
        collaborators,
        joinedTs,
        isFavorite,
        lastHeardTs,
        lastPostedTs,
        lastViewedAt,
        workspaceName,
        workspaceImageUrl,
        type,
        images,
        moreCount,
        unreadCount,
        avatars,
        createdNew,
        settings,
        attachments,
        channelSpans,
        visibility,
        totalMessages,
        totalDurationMilliseconds,
        summaries,
        isAsync,
        asyncStats,
        retentionDays,
        engagementPercentage,
        maxSequenceNumber,
        defaultRole,
        sources,
      ];

  /// Creates a copy of this Conversation with the given fields replaced.
  Conversation copyWith({
    String? id,
    String? name,
    String? workspaceId,
    String? guid,
    String? description,
    DateTime? createdAt,
    // New fields from API schema
    String? workspaceGuid,
    String? channelGuid,
    String? channelName,
    String? channelKind,
    List<String>? sourceChannelIds,
    String? channelDescription,
    String? bgRrggbb,
    String? txtRrggbb,
    String? channelSettings,
    String? imageUrl,
    String? isPrivate,
    String? postRule,
    String? dmHash,
    int? lastUpdatedTs,
    String? sortOrder,
    int? createdTs,
    int? deletedAt,
    String? ownerName,
    String? smsPhone,
    List<ConversationCollaborator>? collaborators,
    int? joinedTs,
    String? isFavorite,
    int? lastHeardTs,
    int? lastPostedTs,
    String? lastViewedAt,
    String? workspaceName,
    String? workspaceImageUrl,
    String? type,
    List<String>? images,
    int? moreCount,
    int? unreadCount,
    ConversationAvatars? avatars,
    bool? createdNew,
    Map<String, dynamic>? settings,
    List<ConversationAttachment>? attachments,
    List<ConversationChannelSpan>? channelSpans,
    String? visibility,
    int? totalMessages,
    int? totalDurationMilliseconds,
    List<ConversationSummary>? summaries,
    bool? isAsync,
    ConversationAsyncStats? asyncStats,
    int? retentionDays,
    int? engagementPercentage,
    int? maxSequenceNumber,
    String? defaultRole,
    List<ConversationSource>? sources,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceId: workspaceId ?? this.workspaceId,
      guid: guid ?? this.guid,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      // New fields from API schema
      workspaceGuid: workspaceGuid ?? this.workspaceGuid,
      channelGuid: channelGuid ?? this.channelGuid,
      channelName: channelName ?? this.channelName,
      channelKind: channelKind ?? this.channelKind,
      sourceChannelIds: sourceChannelIds ?? this.sourceChannelIds,
      channelDescription: channelDescription ?? this.channelDescription,
      bgRrggbb: bgRrggbb ?? this.bgRrggbb,
      txtRrggbb: txtRrggbb ?? this.txtRrggbb,
      channelSettings: channelSettings ?? this.channelSettings,
      imageUrl: imageUrl ?? this.imageUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      postRule: postRule ?? this.postRule,
      dmHash: dmHash ?? this.dmHash,
      lastUpdatedTs: lastUpdatedTs ?? this.lastUpdatedTs,
      sortOrder: sortOrder ?? this.sortOrder,
      createdTs: createdTs ?? this.createdTs,
      deletedAt: deletedAt ?? this.deletedAt,
      ownerName: ownerName ?? this.ownerName,
      smsPhone: smsPhone ?? this.smsPhone,
      collaborators: collaborators ?? this.collaborators,
      joinedTs: joinedTs ?? this.joinedTs,
      isFavorite: isFavorite ?? this.isFavorite,
      lastHeardTs: lastHeardTs ?? this.lastHeardTs,
      lastPostedTs: lastPostedTs ?? this.lastPostedTs,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      workspaceName: workspaceName ?? this.workspaceName,
      workspaceImageUrl: workspaceImageUrl ?? this.workspaceImageUrl,
      type: type ?? this.type,
      images: images ?? this.images,
      moreCount: moreCount ?? this.moreCount,
      unreadCount: unreadCount ?? this.unreadCount,
      avatars: avatars ?? this.avatars,
      createdNew: createdNew ?? this.createdNew,
      settings: settings ?? this.settings,
      attachments: attachments ?? this.attachments,
      channelSpans: channelSpans ?? this.channelSpans,
      visibility: visibility ?? this.visibility,
      totalMessages: totalMessages ?? this.totalMessages,
      totalDurationMilliseconds: totalDurationMilliseconds ?? this.totalDurationMilliseconds,
      summaries: summaries ?? this.summaries,
      isAsync: isAsync ?? this.isAsync,
      asyncStats: asyncStats ?? this.asyncStats,
      retentionDays: retentionDays ?? this.retentionDays,
      engagementPercentage: engagementPercentage ?? this.engagementPercentage,
      maxSequenceNumber: maxSequenceNumber ?? this.maxSequenceNumber,
      defaultRole: defaultRole ?? this.defaultRole,
      sources: sources ?? this.sources,
    );
  }
}

/// Domain entity for conversation collaborator
class ConversationCollaborator extends Equatable {
  const ConversationCollaborator({
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

  final String? userGuid;
  final String? imageUrl;
  final String? firstName;
  final String? lastName;
  final String? permission;
  final String? joined;
  final String? lastPosted;
  final String? firstAccessedAt;
  final String? lastViewedAt;
  final String? status;
  final String? primaryLanguage;

  @override
  List<Object?> get props => [
        userGuid,
        imageUrl,
        firstName,
        lastName,
        permission,
        joined,
        lastPosted,
        firstAccessedAt,
        lastViewedAt,
        status,
        primaryLanguage,
      ];
}

/// Domain entity for conversation avatars
class ConversationAvatars extends Equatable {
  const ConversationAvatars({
    this.avatars,
    this.numRows,
    this.numColumns,
  });

  final List<ConversationAvatar>? avatars;
  final int? numRows;
  final int? numColumns;

  @override
  List<Object?> get props => [avatars, numRows, numColumns];
}

/// Domain entity for individual avatar
class ConversationAvatar extends Equatable {
  const ConversationAvatar({
    this.children,
    this.type,
    this.imageUrl,
    this.text,
  });

  final List<String>? children;
  final String? type;
  final String? imageUrl;
  final String? text;

  @override
  List<Object?> get props => [children, type, imageUrl, text];
}

/// Domain entity for conversation attachment
class ConversationAttachment extends Equatable {
  const ConversationAttachment({
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

  final String? id;
  final String? clientId;
  final String? creatorId;
  final String? createdAt;
  final String? type;
  final String? link;
  final String? activeBegin;
  final String? activeEnd;
  final String? filename;
  final String? mimeType;
  final int? lengthInBytes;
  final ConversationLocation? location;

  @override
  List<Object?> get props => [
        id,
        clientId,
        creatorId,
        createdAt,
        type,
        link,
        activeBegin,
        activeEnd,
        filename,
        mimeType,
        lengthInBytes,
        location,
      ];
}

/// Domain entity for location data
class ConversationLocation extends Equatable {
  const ConversationLocation({
    this.latitude,
    this.longitude,
  });

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Domain entity for channel span
class ConversationChannelSpan extends Equatable {
  const ConversationChannelSpan({
    this.id,
    this.begin,
    this.end,
    this.deletedAt,
    this.requiredUsers,
    this.type,
    this.topic,
  });

  final String? id;
  final String? begin;
  final String? end;
  final String? deletedAt;
  final List<String>? requiredUsers;
  final String? type;
  final String? topic;

  @override
  List<Object?> get props => [id, begin, end, deletedAt, requiredUsers, type, topic];
}

/// Domain entity for conversation summary
class ConversationSummary extends Equatable {
  const ConversationSummary({
    this.channelId,
    this.spanId,
    this.items,
  });

  final String? channelId;
  final String? spanId;
  final List<ConversationSummaryItem>? items;

  @override
  List<Object?> get props => [channelId, spanId, items];
}

/// Domain entity for summary item
class ConversationSummaryItem extends Equatable {
  const ConversationSummaryItem({
    this.userId,
    this.text,
    this.type,
  });

  final String? userId;
  final String? text;
  final String? type;

  @override
  List<Object?> get props => [userId, text, type];
}

/// Domain entity for async stats
class ConversationAsyncStats extends Equatable {
  const ConversationAsyncStats({
    this.channelStats,
    this.userStats,
  });

  final ConversationChannelStats? channelStats;
  final List<ConversationUserStats>? userStats;

  @override
  List<Object?> get props => [channelStats, userStats];
}

/// Domain entity for channel stats
class ConversationChannelStats extends Equatable {
  const ConversationChannelStats({
    this.totalDurationMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalMessagesPosted,
    this.totalUsers,
  });

  final int? totalDurationMilliseconds;
  final int? totalHeardMilliseconds;
  final int? totalEngagedPercentage;
  final int? totalMessagesPosted;
  final int? totalUsers;

  @override
  List<Object?> get props => [
        totalDurationMilliseconds,
        totalHeardMilliseconds,
        totalEngagedPercentage,
        totalMessagesPosted,
        totalUsers,
      ];
}

/// Domain entity for user stats
class ConversationUserStats extends Equatable {
  const ConversationUserStats({
    this.userId,
    this.totalMessagesPosted,
    this.totalSentMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalHeardMessages,
    this.totalUnheardMessages,
  });

  final String? userId;
  final int? totalMessagesPosted;
  final int? totalSentMilliseconds;
  final int? totalHeardMilliseconds;
  final int? totalEngagedPercentage;
  final int? totalHeardMessages;
  final int? totalUnheardMessages;

  @override
  List<Object?> get props => [
        userId,
        totalMessagesPosted,
        totalSentMilliseconds,
        totalHeardMilliseconds,
        totalEngagedPercentage,
        totalHeardMessages,
        totalUnheardMessages,
      ];
}

/// Domain entity for source
class ConversationSource extends Equatable {
  const ConversationSource({
    this.type,
    this.value,
  });

  final String? type;
  final String? value;

  @override
  List<Object?> get props => [type, value];
}
