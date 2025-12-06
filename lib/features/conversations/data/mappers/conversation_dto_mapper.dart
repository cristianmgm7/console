import 'package:carbon_voice_console/features/conversations/data/dtos/conversation_dto.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Extension methods to convert ConversationDto to domain entities
extension ConversationDtoMapper on ConversationDto {
  Conversation toDomain() {
    // Use channelGuid as primary ID
    final id = channelGuid ?? 'unknown';

    // Use channelName as primary name
    final name = channelName ?? 'Unknown Conversation';

    // Use workspaceGuid as workspaceId
    final workspaceId = workspaceGuid ?? 'unknown';

    return Conversation(
      id: id,
      name: name,
      workspaceId: workspaceId,
      guid: channelGuid ?? channelGuid,
      description: channelDescription ?? channelDescription,
      createdAt: createdTs != null ? DateTime.fromMillisecondsSinceEpoch(createdTs!) : null,
      // Keep existing fields for backward compatibility
      workspaceGuid: workspaceGuid,
      channelGuid: channelGuid,
      channelName: channelName,
      channelKind: channelKind,
      sourceChannelIds: sourceChannelIds,
      channelDescription: channelDescription,
      bgRrggbb: bgRrggbb,
      txtRrggbb: txtRrggbb,
      channelSettings: channelSettings,
      imageUrl: imageUrl,
      isPrivate: isPrivate,
      postRule: postRule,
      dmHash: dmHash,
      lastUpdatedTs: lastUpdatedTs,
      sortOrder: sortOrder,
      createdTs: createdTs,
      deletedAt: deletedAt,
      ownerName: ownerName,
      smsPhone: smsPhone,
      collaborators: jsonCollaborators?.map((dto) => dto.toDomain()).toList(),
      joinedTs: joinedTs,
      isFavorite: isFavorite,
      lastHeardTs: lastHeardTs,
      lastPostedTs: lastPostedTs,
      lastViewedAt: lastViewedAt,
      workspaceName: workspaceName,
      workspaceImageUrl: workspaceImageUrl,
      type: type,
      images: images,
      moreCount: moreCount,
      unreadCount: unreadCnt,
      avatars: avatars?.toDomain(),
      createdNew: createdNew,
      settings: settings,
      attachments: attachments?.map((dto) => dto.toDomain()).toList(),
      channelSpans: channelSpans?.map((dto) => dto.toDomain()).toList(),
      visibility: visibility,
      totalMessages: totalMessages,
      totalDurationMilliseconds: totalDurationMilliseconds,
      summaries: summaries?.map((dto) => dto.toDomain()).toList(),
      isAsync: isAsync,
      asyncStats: asyncStats?.toDomain(),
      retentionDays: retentionDays,
      engagementPercentage: engagementPercentage,
      maxSequenceNumber: maxSequenceNumber,
      defaultRole: defaultRole,
      sources: sources?.map((dto) => dto.toDomain()).toList(),
    );
  }
}

extension ConversationCollaboratorDtoMapper on ConversationCollaboratorDto {
  ConversationCollaborator toDomain() {
    return ConversationCollaborator(
      userGuid: userGuid,
      imageUrl: imageUrl,
      firstName: firstName,
      lastName: lastName,
      permission: permission,
      joined: joined,
      lastPosted: lastPosted,
      firstAccessedAt: firstAccessedAt,
      lastViewedAt: lastViewedAt,
      status: status,
      primaryLanguage: primaryLanguage,
    );
  }
}

extension ConversationAvatarsDtoMapper on ConversationAvatarsDto {
  ConversationAvatars toDomain() {
    return ConversationAvatars(
      avatars: avatars?.map((dto) => dto.toDomain()).toList(),
      numRows: numRows,
      numColumns: numColumns,
    );
  }
}

extension ConversationAvatarDtoMapper on ConversationAvatarDto {
  ConversationAvatar toDomain() {
    return ConversationAvatar(
      children: children?.map((dto) => dto.toDomain()).toList(),
      type: type,
      imageUrl: imageUrl,
      text: text,
    );
  }
}

extension ConversationAttachmentDtoMapper on ConversationAttachmentDto {
  ConversationAttachment toDomain() {
    return ConversationAttachment(
      id: id,
      clientId: clientId,
      creatorId: creatorId,
      createdAt: createdAt,
      type: type,
      link: link,
      activeBegin: activeBegin,
      activeEnd: activeEnd,
      filename: filename,
      mimeType: mimeType,
      lengthInBytes: lengthInBytes,
      location: location?.toDomain(),
    );
  }
}

extension ConversationLocationDtoMapper on ConversationLocationDto {
  ConversationLocation toDomain() {
    return ConversationLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

extension ConversationChannelSpanDtoMapper on ConversationChannelSpanDto {
  ConversationChannelSpan toDomain() {
    return ConversationChannelSpan(
      id: id,
      begin: begin,
      end: end,
      deletedAt: deletedAt,
      requiredUsers: requiredUsers,
      type: type,
      topic: topic,
    );
  }
}

extension ConversationSummaryDtoMapper on ConversationSummaryDto {
  ConversationSummary toDomain() {
    return ConversationSummary(
      channelId: channelId,
      spanId: spanId,
      items: items?.map((dto) => dto.toDomain()).toList(),
    );
  }
}

extension ConversationSummaryItemDtoMapper on ConversationSummaryItemDto {
  ConversationSummaryItem toDomain() {
    return ConversationSummaryItem(
      userId: userId,
      text: text,
      type: type,
    );
  }
}

extension ConversationAsyncStatsDtoMapper on ConversationAsyncStatsDto {
  ConversationAsyncStats toDomain() {
    return ConversationAsyncStats(
      channelStats: channelStats?.toDomain(),
      userStats: userStats?.map((dto) => dto.toDomain()).toList(),
    );
  }
}

extension ConversationChannelStatsDtoMapper on ConversationChannelStatsDto {
  ConversationChannelStats toDomain() {
    return ConversationChannelStats(
      totalDurationMilliseconds: totalDurationMilliseconds,
      totalHeardMilliseconds: totalHeardMilliseconds,
      totalEngagedPercentage: totalEngagedPercentage,
      totalMessagesPosted: totalMessagesPosted,
      totalUsers: totalUsers,
    );
  }
}

extension ConversationUserStatsDtoMapper on ConversationUserStatsDto {
  ConversationUserStats toDomain() {
    return ConversationUserStats(
      userId: userId,
      totalMessagesPosted: totalMessagesPosted,
      totalSentMilliseconds: totalSentMilliseconds,
      totalHeardMilliseconds: totalHeardMilliseconds,
      totalEngagedPercentage: totalEngagedPercentage,
      totalHeardMessages: totalHeardMessages,
      totalUnheardMessages: totalUnheardMessages,
    );
  }
}

extension ConversationSourceDtoMapper on ConversationSourceDto {
  ConversationSource toDomain() {
    return ConversationSource(
      type: type,
      value: value,
    );
  }
}
