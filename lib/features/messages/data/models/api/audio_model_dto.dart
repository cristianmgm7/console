import 'package:json_annotation/json_annotation.dart';

part 'audio_model_dto.g.dart';

/// DTO for audio model in message
@JsonSerializable()
class AudioModelDto {
  const AudioModelDto({
    required this.id,
    required this.url,
    required this.streaming,
    required this.language,
    required this.durationMs,
    required this.waveformPercentages,
    required this.isOriginalAudio,
    required this.extension,
  });

  factory AudioModelDto.fromJson(Map<String, dynamic> json) => _$AudioModelDtoFromJson(json);

  @JsonKey(name: '_id', defaultValue: 'unknown')
  final String id;

  final String url;
  final bool streaming;
  final String language;

  @JsonKey(name: 'duration_ms')
  final int durationMs;

  @JsonKey(name: 'waveform_percentages')
  final List<double> waveformPercentages;

  @JsonKey(name: 'is_original_audio')
  final bool isOriginalAudio;

  final String extension;

  Map<String, dynamic> toJson() => _$AudioModelDtoToJson(this);
}
