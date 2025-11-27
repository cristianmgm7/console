import 'package:carbon_voice_console/features/messages/data/models/message_model.dart';

/// DTO for the message detail endpoint response
/// Endpoint: /v5/messages/{messageId} or /v4/messages/{messageId}
/// Response format: {"channel_id": "...", "messages": [{message}]}
class MessageDetailResponseDto {
  const MessageDetailResponseDto({
    required this.channelId,
    required this.messages,
  });

  final String channelId;
  final List<MessageModel> messages;

  /// Creates from raw JSON response
  /// Expects JSON already has messages normalized via JsonNormalizer
  factory MessageDetailResponseDto.fromJson(
    Map<String, dynamic> json,
    List<MessageModel> normalizedMessages,
  ) {
    final channelId = json['channel_id'] as String?;
    if (channelId == null) {
      throw FormatException('Detail response missing channel_id: $json');
    }

    return MessageDetailResponseDto(
      channelId: channelId,
      messages: normalizedMessages,
    );
  }

  /// Gets the first message from the response
  /// Detail endpoint always returns single message in array
  MessageModel get firstMessage {
    if (messages.isEmpty) {
      throw StateError('Detail response has empty messages array');
    }
    return messages.first;
  }
}
