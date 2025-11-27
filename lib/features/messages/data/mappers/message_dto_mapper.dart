import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/timecode.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';

/// Extension methods to convert DTOs to domain entities
extension MessageDtoMapper on MessageDto {
  Message toDomain() {
    return Message(
      id: messageId,
      creatorId: creatorId,
      createdAt: createdAt,
      workspaceIds: workspaceIds,
      channelIds: channelIds,
      duration: Duration(milliseconds: durationMs),
      audioModels: audioModels.map((dto) => dto.toDomain()).toList(),
      textModels: textModels.map((dto) => dto.toDomain()).toList(),
      status: status,
      type: type,
      lastHeardAt: lastHeardAt,
      heardDuration: Duration(milliseconds: heardMs),
      totalHeardDuration: Duration(milliseconds: totalHeardMs),
      isTextMessage: isTextMessage,
      notes: notes,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

extension AudioModelDtoMapper on AudioModelDto {
  AudioModel toDomain() {
    return AudioModel(
      id: id,
      url: url,
      isStreaming: streaming,
      language: language,
      duration: Duration(milliseconds: durationMs),
      waveformData: waveformPercentages,
      isOriginal: isOriginalAudio,
      format: extension,
    );
  }
}

extension TextModelDtoMapper on TextModelDto {
  TextModel toDomain() {
    return TextModel(
      type: type,
      audioId: audioId,
      language: languageId,
      text: value,
      timecodes: timecodes.map((dto) => dto.toDomain()).toList(),
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
