import 'package:carbon_voice_console/features/messages/data/mappers/message_dto_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';

/// Extension methods to convert DTOs to domain entities
extension VoiceMemoDtoMapper on VoiceMemoDto {
  VoiceMemo toDomain() {
    if (messageId == null || creatorId == null || createdAt == null) {
      throw FormatException(
        'Required voice memo fields are missing: id=${messageId == null}, '
        'creator=${creatorId == null}, created=${createdAt == null}',
      );
    }

    return VoiceMemo(
      id: messageId!,
      creatorId: creatorId!,
      createdAt: DateTime.parse(createdAt!),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
      lastUpdatedAt: lastUpdatedAt != null ? DateTime.parse(lastUpdatedAt!) : null,
      workspaceIds: workspaceIds ?? [],
      channelIds: channelIds ?? [],
      parentMessageId: parentMessageId,
      heardMs: heardMs,
      notes: notes ?? '',
      name: name,
      isTextMessage: isTextMessage ?? false,
      status: status ?? 'unknown',
      type: type ?? 'voicememo',
      // Reuses existing mappers from messages feature (AudioModelDtoMapper, TextModelDtoMapper)
      audioModels:
          audioModels
              ?.map((dto) {
                try {
                  return dto.toDomain(); // Uses AudioModelDtoMapper from message_dto_mapper.dart
                } on Exception {
                  return null; // Skip invalid audio models
                }
              })
              .whereType<AudioModel>()
              .toList() ??
          [],
      textModels:
          textModels
              ?.map((dto) {
                try {
                  return dto.toDomain(); // Uses TextModelDtoMapper from message_dto_mapper.dart
                } on Exception {
                  return null; // Skip invalid text models
                }
              })
              .whereType<TextModel>()
              .toList() ??
          [],
      folderId: folderId,
      lastHeardAt: lastHeardAt != null ? DateTime.parse(lastHeardAt!) : null,
      totalHeardMs: totalHeardMs,
      duration: Duration(milliseconds: durationMs ?? 0),
    );
  }
}
