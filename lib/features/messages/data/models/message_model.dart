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

  /// Creates a MessageModel from normalized JSON
  /// Expects JSON already normalized by JsonNormalizer at data source boundary
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw FormatException('Message JSON missing required id field: $json');
    }

    final conversationId = json['conversationId'] as String?;
    if (conversationId == null) {
      throw FormatException('Message JSON missing required conversationId field: $json');
    }

    final userId = json['userId'] as String?;
    if (userId == null) {
      throw FormatException('Message JSON missing required userId field: $json');
    }

    return MessageModel(
      id: id,
      conversationId: conversationId,
      userId: userId,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      text: json['text'] as String?,
      transcript: json['transcript'] as String?,
      audioUrl: json['audioUrl'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
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
