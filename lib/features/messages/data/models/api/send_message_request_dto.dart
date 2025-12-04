import 'package:carbon_voice_console/features/messages/data/models/api/utm_data_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_message_request_dto.g.dart';

/// DTO for sending a message to the API
@JsonSerializable()
class SendMessageRequestDto {
  const SendMessageRequestDto({
    required this.transcript,
    required this.isTextMessage,
    required this.channelId,
    required this.workspaceGuid,
    this.uniqueClientId,
    this.releaseDate,
    this.utmData,
    this.isStreaming = false,
    this.announceUser = true,
    this.voice,
    this.kind = 'text',
    this.replyToMessageId,
    this.createForward,
  });

  factory SendMessageRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestDtoFromJson(json);

  final String transcript;

  @JsonKey(name: 'is_text_message')
  final bool isTextMessage;

  @JsonKey(name: 'unique_client_id')
  final String? uniqueClientId;

  @JsonKey(name: 'release_date')
  final DateTime? releaseDate;

  @JsonKey(name: 'utm_data')
  final UtmDataDto? utmData;

  @JsonKey(name: 'is_streaming')
  final bool isStreaming;

  @JsonKey(name: 'announce_user')
  final bool announceUser;

  final String? voice;

  final String kind;

  @JsonKey(name: 'channel_id')
  final String channelId;

  @JsonKey(name: 'workspace_guid')
  final String workspaceGuid;

  @JsonKey(name: 'reply_to_message_id')
  final String? replyToMessageId;

  @JsonKey(name: 'createForward')
  final CreateForwardDto? createForward;

  Map<String, dynamic> toJson() => _$SendMessageRequestDtoToJson(this);
}

/// DTO for forward message creation
@JsonSerializable()
class CreateForwardDto {
  const CreateForwardDto({
    required this.forwardedMessageId,
    this.endAccessAt,
  });

  factory CreateForwardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateForwardDtoFromJson(json);

  @JsonKey(name: 'forwarded_message_id')
  final String forwardedMessageId;

  @JsonKey(name: 'end_access_at')
  final DateTime? endAccessAt;

  Map<String, dynamic> toJson() => _$CreateForwardDtoToJson(this);
}
