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
    // Handle new API format where message data might be nested in 'text' field
    final textData = json['text'];
    final actualJson = (textData is Map<String, dynamic>) ? textData : json;

    // Handle new API format with message_id, creator_id, channel_ids array, etc.
    final messageId = actualJson['id'] ??
                     actualJson['_id'] ??
                     actualJson['messageId'] ??
                     actualJson['message_id'] ??
                     json['id']; // fallback to original json

    // channel_ids is an array, take the first one
    final channelIds = actualJson['channel_ids'] as List<dynamic>?;
    final conversationId = actualJson['conversationId'] ??
        actualJson['conversation_id'] ??
        actualJson['channelId'] ??
        actualJson['channel_id'] ??
        (channelIds != null && channelIds.isNotEmpty ? channelIds.first.toString() : null);

    final creatorId = actualJson['creator_id'];
    final userId = actualJson['userId'] ??
        actualJson['user_id'] ??
        actualJson['ownerId'] ??
        actualJson['owner_id'] ??
        creatorId;
    
    // Extract audio URL from audio_models array or nested audio object
    final audioModels = actualJson['audio_models'] as List<dynamic>?;
    String? audioUrl;
    if (audioModels != null && audioModels.isNotEmpty) {
      final firstAudio = audioModels.first as Map<String, dynamic>?;
      audioUrl = firstAudio?['url'] as String?;
    }

    // Check for nested audio object in the original json
    final audioData = json['audio'] as Map<String, dynamic>?;
    if (audioData != null && audioUrl == null) {
      audioUrl = audioData['url'] as String?;
    }

    // Extract transcript from text_models array
    final textModels = actualJson['text_models'] as List<dynamic>?;
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

    // Check for transcript in the original json
    final originalTranscript = json['transcript'];
    if (originalTranscript != null && transcript == null) {
      transcript = originalTranscript.toString();
    }

    // Convert duration_ms to seconds
    final durationMsValue = actualJson['duration_ms'] ?? audioData?['duration_ms'];
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
      'createdAt': actualJson['createdAt'] ??
                   actualJson['created_at'] ??
                   actualJson['date'] ??
                   json['createdAt'], // fallback to original
      'text': actualJson['text'] ?? actualJson['message'] ?? json['text'],
      'transcript': transcript,
      'audioUrl': audioUrl,
      'duration': actualJson['duration'] ??
                  actualJson['durationSeconds'] ??
                  duration,
      'status': actualJson['status'] ?? json['status'],
      'metadata': actualJson['metadata'] ?? json['metadata'],
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

