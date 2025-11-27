import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';

/// DTO for text model in message
class TextModelDto {
  const TextModelDto({
    required this.type,
    required this.audioId,
    required this.languageId,
    required this.value,
    required this.timecodes,
  });

  factory TextModelDto.fromJson(Map<String, dynamic> json) {
    return TextModelDto(
      type: json['type'] as String,
      audioId: json['audio_id'] as String,
      languageId: json['language_id'] as String,
      value: json['value'] as String,
      timecodes: (json['timecodes'] as List<dynamic>)
          .map((e) => TimecodeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String type;
  final String audioId;
  final String languageId;
  final String value;
  final List<TimecodeDto> timecodes;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'audio_id': audioId,
      'language_id': languageId,
      'value': value,
      'timecodes': timecodes.map((e) => e.toJson()).toList(),
    };
  }
}
