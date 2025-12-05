/// Utility for normalizing API JSON responses to consistent field names
/// This handles the mismatch between API field names and our domain model expectations
class JsonNormalizer {
  // REMOVED: normalizeWorkspace method
  // Workspaces now use WorkspaceDto with @JsonSerializable() annotations

  /// Normalizes conversation JSON from API format to our expected format
  /// @deprecated Use ConversationDto.fromJson() directly instead.
  /// DTOs with json_serializable now handle field mapping automatically.
  @Deprecated('Use ConversationDto.fromJson() directly - DTOs handle field mapping now')
  static Map<String, dynamic> normalizeConversation(Map<String, dynamic> json) {
    // Pass through unchanged - DTOs handle the mapping now
    return Map<String, dynamic>.from(json);
  }

  /// Normalizes message JSON from API format to our expected format
  static Map<String, dynamic> normalizeMessage(Map<String, dynamic> json) {
    // Handle new API format where message data might be nested in various fields
    final possibleContainers = ['text', 'message', 'data'];
    Map<String, dynamic>? nestedData;

    for (final field in possibleContainers) {
      final data = json[field];
      if (data is Map<String, dynamic>) {
        nestedData = data;
        break;
      }
    }

    final actualJson = nestedData ?? json;

    // Extract critical message fields that must be present for Message entity
    final messageId = actualJson['message_id'] ??
                     actualJson['id'] ??
                     actualJson['_id'] ??
                     actualJson['messageId'] ??
                     json['message_id'] ??
                     json['id'] ??
                     json['_id'] ??
                     json['messageId'];

    final creatorId = actualJson['creator_id'] ??
                     actualJson['user_id'] ??
                     actualJson['creatorId'] ??
                     json['creator_id'] ??
                     json['user_id'] ??
                     json['creatorId'];

    final createdAt = actualJson['created_at'] ??
                     actualJson['createdAt'] ??
                     actualJson['date'] ??
                     json['created_at'] ??
                     json['createdAt'] ??
                     json['date'];
    
    // Extract audio URL from audio_models array or nested audio object
    final audioModels = actualJson['audio_models'] as List<dynamic>?;
    String? audioUrl;
    if (audioModels != null && audioModels.isNotEmpty) {
      final firstAudio = audioModels.first as Map<String, dynamic>?;
      audioUrl = firstAudio?['url'] as String?;
    }

    // Check for nested audio object - prioritize actualJson (unwrapped), fallback to original
    final audioData = actualJson['audio'] as Map<String, dynamic>? ??
                     json['audio'] as Map<String, dynamic>?;
    if (audioData != null && audioUrl == null) {
      audioUrl = audioData['url'] as String?;
    }

    // Handle different audio data structures from various endpoints
    // Normalize audio models if they exist in different formats
    List<dynamic>? normalizedAudioModels;
    if (audioModels != null && audioModels.isNotEmpty) {
      normalizedAudioModels = audioModels.map((audioJson) {
        if (audioJson is Map<String, dynamic>) {
          // Check if this audio model needs normalization
          final hasExpectedFields = audioJson.containsKey('_id') &&
                               audioJson.containsKey('url') &&
                               audioJson.containsKey('streaming');
          if (!hasExpectedFields) {
            // Normalize to expected AudioModelDto format
            return normalizeAudioModel(audioJson);
          }
          return audioJson; // Already in correct format
        }
        return audioJson;
      }).toList();
    } else if (audioData != null) {
      // If there's no audio_models array but there's an audio object,
      // normalize the audio object and create an audio_models array
      normalizedAudioModels = [normalizeAudioModel(audioData)];
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

    // Check for transcript - prioritize actualJson (unwrapped), fallback to original
    final transcriptValue = actualJson['transcript'] ?? json['transcript'];
    if (transcriptValue != null && transcript == null) {
      transcript = transcriptValue.toString();
    }

    // Duration handling is done within audio model normalization if needed

    // Create a copy of the original JSON to modify
    final normalizedJson = Map<String, dynamic>.from(actualJson);

    // Normalize audio models in place if they exist
    if (normalizedAudioModels != null) {
      normalizedJson['audio_models'] = normalizedAudioModels;
    }

    // Ensure critical message fields are present with correct field names
    if (messageId != null) {
      normalizedJson['message_id'] = messageId;
    }
    if (creatorId != null) {
      normalizedJson['creator_id'] = creatorId;
    }
    if (createdAt != null) {
      normalizedJson['created_at'] = createdAt;
    }

    // Ensure required MessageDto fields have default values to prevent null casting errors
    if (!normalizedJson.containsKey('utm_data') || normalizedJson['utm_data'] == null) {
      normalizedJson['utm_data'] = <String, dynamic>{}; // Will be handled by UtmDataDtoConverter
    }
    if (!normalizedJson.containsKey('reaction_summary') || normalizedJson['reaction_summary'] == null) {
      normalizedJson['reaction_summary'] = <String, dynamic>{}; // Will be handled by ReactionSummaryDtoConverter
    }

    // Add extracted fields that might not be in the original JSON
    if (transcript != null && !normalizedJson.containsKey('transcript')) {
      normalizedJson['transcript'] = transcript;
    }
    if (audioUrl != null && !normalizedJson.containsKey('audio_url')) {
      normalizedJson['audio_url'] = audioUrl;
    }

    return normalizedJson;
  }

  /// Normalizes audio model JSON from various API formats to our expected format
  static Map<String, dynamic> normalizeAudioModel(Map<String, dynamic> json) {
    final normalized = {
      '_id': json['_id'] ?? json['id'] ?? json['audio_id'] ?? json['audioId'] ?? 'unknown',
      'url': json['url'] ?? json['audio_url'] ?? json['audioUrl'] ?? json['stream_url'] ?? '',
      'streaming': json['streaming'] ?? json['is_streaming'] ?? json['can_stream'] ?? true,
      'language': json['language'] ?? json['lang'] ?? 'en',
      'duration_ms': json['duration_ms'] ?? json['durationMs'] ?? json['duration'] ?? 0,
      'waveform_percentages': json['waveform_percentages'] ??
                             json['waveformPercentages'] ??
                             json['waveform'] ??
                             <double>[],
      'is_original_audio': json['is_original_audio'] ??
                          json['isOriginalAudio'] ??
                          json['is_original'] ??
                          json['original'] ??
                          true,
      'extension': json['extension'] ?? json['format'] ?? json['file_extension'] ?? 'mp3',
    };

    // Ensure required string fields are not empty
    if ((normalized['_id'] as String).isEmpty) {
      normalized['_id'] = 'unknown';
    }
    if ((normalized['url'] as String).isEmpty) {
      normalized['url'] = 'unknown';
    }
    if ((normalized['language'] as String).isEmpty) {
      normalized['language'] = 'en';
    }
    if ((normalized['extension'] as String).isEmpty) {
      normalized['extension'] = 'mp3';
    }

    return normalized;
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
