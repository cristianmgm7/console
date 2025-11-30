import 'package:json_annotation/json_annotation.dart';

part 'timecode_dto.g.dart';

/// DTO for timecode in text model
// ignore_for_file: sort_constructors_first
@JsonSerializable()
class TimecodeDto {
  const TimecodeDto({
    required this.text,
    required this.start,
    required this.end,
  });

  @JsonKey(name: 't')
  final String text;

  @JsonKey(name: 's')
  final int start;

  @JsonKey(name: 'e')
  final int end;

  factory TimecodeDto.fromJson(Map<String, dynamic> json) => _$TimecodeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimecodeDtoToJson(this);
}
