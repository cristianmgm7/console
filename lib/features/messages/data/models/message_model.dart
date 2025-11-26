import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';

/// Data model for message with JSON serialization
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.userId,
    required super.createdAt,
    super.text,
    super.transcript,
    super.audioUrl,
    super.duration,
    super.status,
    super.metadata,
  });

  /// Creates a MessageModel from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? json['messageId'] as String,
      conversationId: json['conversationId'] as String? ??
                      json['conversation_id'] as String? ??
                      json['channelId'] as String? ??
                      json['channel_id'] as String,
      userId: json['userId'] as String? ??
              json['user_id'] as String? ??
              json['ownerId'] as String? ??
              json['owner_id'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : json['date'] != null
                  ? DateTime.parse(json['date'] as String)
                  : DateTime.now(),
      text: json['text'] as String? ?? json['message'] as String?,
      transcript: json['transcript'] as String?,
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : json['durationSeconds'] != null
              ? Duration(seconds: json['durationSeconds'] as int)
              : null,
      status: json['status'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts MessageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (text != null) 'text': text,
      if (transcript != null) 'transcript': transcript,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (duration != null) 'duration': duration!.inSeconds,
      if (status != null) 'status': status,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Converts to domain entity
  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      userId: userId,
      createdAt: createdAt,
      text: text,
      transcript: transcript,
      audioUrl: audioUrl,
      duration: duration,
      status: status,
      metadata: metadata,
    );
  }
}
