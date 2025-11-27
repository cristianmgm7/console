import 'package:json_annotation/json_annotation.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';

part 'text_model_dto.g.dart';

/// DTO for text model in message
@JsonSerializable()
class TextModelDto {
  const TextModelDto({
    required this.type,
    required this.audioId,
    required this.languageId,
    required this.value,
    required this.timecodes,
  });

  final String type;

  @JsonKey(name: 'audio_id')
  final String audioId;

  @JsonKey(name: 'language_id')
  final String languageId;

  final String value;
  final List<TimecodeDto> timecodes;

  factory TextModelDto.fromJson(Map<String, dynamic> json) => _$TextModelDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TextModelDtoToJson(this);
}
