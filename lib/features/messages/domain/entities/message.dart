import 'package:equatable/equatable.dart';

/// Domain entity representing a message
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.createdAt,
    this.text,
    this.transcript,
    this.audioUrl,
    this.duration,
    this.status,
    this.metadata,
  });

  final String id;
  final String conversationId;
  final String userId;
  final DateTime createdAt;
  final String? text;
  final String? transcript;
  final String? audioUrl;
  final Duration? duration;
  final String? status;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userId,
        createdAt,
        text,
        transcript,
        audioUrl,
        duration,
        status,
        metadata,
      ];
}

