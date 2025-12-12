import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_detail_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/timecode.dart';

/// Extension methods to convert DTOs to domain entities
extension MessageDtoMapper on MessageDto {
  Message toDomain() {
    if (messageId == null || creatorId == null || createdAt == null) {
      throw FormatException('Required message fields are missing: id=${messageId == null}, creator=${creatorId == null}, created=${createdAt == null}');
    }
    return Message(
      id: messageId!,
      creatorId: creatorId!,
      createdAt: createdAt!,
      workspaceIds: workspaceIds ?? [],
      channelIds: channelIds ?? [],
      duration: Duration(milliseconds: durationMs ?? 0),
      audioModels: audioModels?.map((dto) {
        try {
          return dto.toDomain();
        } on Exception {

          return null; // Skip invalid audio models
        }
      }).where((model) => model != null).cast<AudioModel>().toList() ?? [],
      textModels: textModels?.map((dto) {
        try {
          return dto.toDomain();
        } on Exception {
          return null; // Skip invalid text models
        }
      }).where((model) => model != null).cast<TextModel>().toList() ?? [],
      status: status ?? 'unknown',
      type: type ?? 'unknown',
      lastHeardAt: lastHeardAt,
      heardDuration: heardMs != null ? Duration(milliseconds: heardMs!) : null,
      totalHeardDuration: totalHeardMs != null ? Duration(milliseconds: totalHeardMs!) : null,
      isTextMessage: isTextMessage ?? false,
      notes: notes ?? '',
      lastUpdatedAt: lastUpdatedAt,
      parentMessageId: parentMessageId,
      deletedAt: deletedAt,
    );
  }
}

extension AudioModelDtoMapper on AudioModelDto {
  AudioModel toDomain() {
    return AudioModel(
      id: id ?? 'unknown',
      url: url,
      presignedUrl: presignedUrl,
      presignedUrlExpiration: presignedUrlExpiration,
      isStreaming: streaming ?? (streamingUrl != null),
      language: language ?? 'unknown',
      duration: Duration(milliseconds: durationMs),
      waveformData: waveformPercentages,
      isOriginal: isOriginalAudio ?? true,
      format: extension ?? 'mp3',
    );
  }
}

extension TextModelDtoMapper on TextModelDto {
  TextModel? toDomain() {
    // Only create domain entity if required fields are not null
    if (type == null || audioId == null || languageId == null || value == null || timecodes == null) {
      return null;
    }

    return TextModel(
      type: type!,
      audioId: audioId!,
      language: languageId!,
      text: value!,
      timecodes: timecodes!.map((dto) => dto.toDomain()).toList(),
    );
  }
}

extension TimecodeDtoMapper on TimecodeDto {
  Timecode toDomain() {
    return Timecode(
      text: text,
      startTime: Duration(milliseconds: start),
      endTime: Duration(milliseconds: end),
    );
  }
}

extension MessageDetailDtoMapper on MessageDetailDto {
  Message toDomain() {
    // Validate required fields
    if (id == null || creatorId == null || createdAt == null) {
      throw FormatException('Required message fields are missing: id=${id == null}, creator=${creatorId == null}, created=${createdAt == null}');
    }

    // Convert audio model to domain entity (single object, not list)
    final audioModels = <AudioModel>[];
    if (audio != null) {
      audioModels.add(audio!.toDomain());
    }

    // Create text model from transcript and time codes
    // Use first audio model's id as audioId, or empty string if no audio
    final audioId = audioModels.isNotEmpty ? audioModels.first.id : '';
    final textModels = <TextModel>[];
    if (transcript != null) {
      textModels.add(TextModel(
        type: 'transcript', // Default type for message detail
        audioId: audioId,
        language: language ?? 'unknown',
        text: transcript!,
        timecodes: timeCodes?.map((dto) => dto.toDomain()).toList() ?? [],
      ));
    }

    return Message(
      id: id!,
      creatorId: creatorId!,
      createdAt: createdAt!,
      workspaceIds: workspaceId != null ? [workspaceId!] : [],
      channelIds: conversationId != null ? [conversationId!] : [],
      duration: Duration.zero, // Not provided in detail DTO
      audioModels: audioModels,
      textModels: textModels,
      status: status ?? 'unknown',
      type: type ?? 'unknown',
      notes: (aiSummary?.isNotEmpty ?? false) ? aiSummary! : (transcript ?? ''),
      lastUpdatedAt: updatedAt,
      parentMessageId: parentMessageId,
    );
  }
}
