import 'package:carbon_voice_console/features/messages/data/models/api/send_message_request_dto.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:uuid/uuid.dart';

/// Maps domain SendMessageRequest to DTO
extension SendMessageRequestMapper on SendMessageRequest {
  SendMessageRequestDto toDto() {
    return SendMessageRequestDto(
      transcript: text,
      isTextMessage: true,
      channelId: channelId,
      workspaceGuid: workspaceId,
      uniqueClientId: const Uuid().v4(), // Generate unique client ID
      releaseDate: DateTime.now(),
      kind: 'text',
      replyToMessageId: replyToMessageId,
    );
  }
}
