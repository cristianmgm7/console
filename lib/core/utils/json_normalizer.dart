/// Utility for normalizing API JSON responses to consistent field names
/// This handles the mismatch between API field names and our domain model expectations
class JsonNormalizer {
  /// Normalizes workspace JSON from API format to our expected format
  static Map<String, dynamic> normalizeWorkspace(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['_id'] ?? json['workspace_guid'],
      'name': json['name'] ?? json['workspace_name'] ?? 'Unknown Workspace',
      'guid': json['guid'] ?? json['workspace_guid'],
      'description': json['description'] ?? json['workspace_description'],
    };
  }

  /// Normalizes conversation JSON from API format to our expected format
  static Map<String, dynamic> normalizeConversation(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['_id'] ?? json['channel_guid'],
      'name': json['name'] ?? json['channel_name'] ?? 'Unknown Conversation',
      'workspaceId': json['workspaceId'] ?? json['workspace_id'] ?? json['workspace_guid'],
      'guid': json['guid'] ?? json['channel_guid'],
      'description': json['description'] ?? json['channel_description'],
      'createdAt': json['createdAt'] ?? json['created_at'],
      'messageCount': json['messageCount'] ?? json['message_count'],
    };
  }

  /// Normalizes message JSON from API format to our expected format
  static Map<String, dynamic> normalizeMessage(Map<String, dynamic> json) {
    // Handle new API format with message_id, creator_id, channel_ids array, etc.
    final messageId = json['id'] ?? 
                     json['_id'] ?? 
                     json['messageId'] ?? 
                     json['message_id'];
    
    // channel_ids is an array, take the first one
    final channelIds = json['channel_ids'] as List<dynamic>?;
    final conversationId = json['conversationId'] ??
        json['conversation_id'] ??
        json['channelId'] ??
        json['channel_id'] ??
        (channelIds != null && channelIds.isNotEmpty ? channelIds.first.toString() : null);
    
    final creatorId = json['creator_id'];
    final userId = json['userId'] ??
        json['user_id'] ??
        json['ownerId'] ??
        json['owner_id'] ??
        creatorId;
    
    // Extract audio URL from audio_models array
    final audioModels = json['audio_models'] as List<dynamic>?;
    String? audioUrl;
    if (audioModels != null && audioModels.isNotEmpty) {
      final firstAudio = audioModels.first as Map<String, dynamic>?;
      audioUrl = firstAudio?['url'] as String?;
    }
    
    // Extract transcript from text_models array
    final textModels = json['text_models'] as List<dynamic>?;
    String? transcript;
    if (textModels != null) {
      // Look for transcript_with_timecode type
      for (final textModel in textModels) {
        if (textModel is Map<String, dynamic>) {
          final type = textModel['type'] as String?;
          if (type == 'transcript_with_timecode' || type == 'transcript') {
            transcript = textModel['value'] as String?;
            break;
          }
        }
      }
    }
    
    // Convert duration_ms to seconds
    final durationMsValue = json['duration_ms'];
    final durationMs = durationMsValue is int
        ? durationMsValue
        : durationMsValue is double
            ? durationMsValue.toInt()
            : null;
    final duration = durationMs != null ? durationMs ~/ 1000 : null;
    
    return {
      'id': messageId,
      'conversationId': conversationId,
      'userId': userId,
      'createdAt': json['createdAt'] ?? 
                   json['created_at'] ?? 
                   json['date'],
      'text': json['text'] ?? json['message'],
      'transcript': transcript ?? json['transcript'],
      'audioUrl': audioUrl ?? json['audioUrl'] ?? json['audio_url'],
      'duration': json['duration'] ?? 
                  json['durationSeconds'] ?? 
                  duration,
      'status': json['status'],
      'metadata': json['metadata'],
    };
  }

  /// Normalizes user JSON from API format to our expected format
  static Map<String, dynamic> normalizeUser(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? json['_id'] ?? json['userId'] ?? json['user_guid'],
      'name': json['name'] ?? json['username'] ?? 'Unknown User',
      'email': json['email'],
      'avatarUrl': json['avatarUrl'] ?? json['avatar_url'] ?? json['image_url'],
      'workspaceId': json['workspaceId'] ?? json['workspace_id'],
    };
  }
}

