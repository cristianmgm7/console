import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_model_dto.g.dart';

/// DTO for text model in message
@JsonSerializable()
class TextModelDto {
  const TextModelDto({
    this.type,
    this.audioId,
    this.languageId,
    this.value,
    this.timecodes,
  });

  factory TextModelDto.fromJson(Map<String, dynamic> json) => _$TextModelDtoFromJson(json);

  final String? type;

  @JsonKey(name: 'audio_id')
  final String? audioId;

  @JsonKey(name: 'language_id')
  final String? languageId;

  final String? value;
  final List<TimecodeDto>? timecodes;

  Map<String, dynamic> toJson() => _$TextModelDtoToJson(this);
}
