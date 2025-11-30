import 'package:json_annotation/json_annotation.dart';

part 'audio_model_dto.g.dart';

/// DTO for audio model in message
@JsonSerializable()
class AudioModelDto {
  const AudioModelDto({
    this.id,
    required this.url,
    this.streamingUrl,
    this.presignedUrl,
    this.presignedUrlExpiration,
    required this.durationMs,
    required this.waveformPercentages,
    this.language,
    this.isOriginalAudio,
    this.extension,
  });

  factory AudioModelDto.fromJson(Map<String, dynamic> json) => _$AudioModelDtoFromJson(json);

  @JsonKey(name: '_id', defaultValue: 'unknown')
  final String? id;

  final String url;

  @JsonKey(name: 'streaming_url')
  final String? streamingUrl;

  @JsonKey(name: 'presigned_url')
  final String? presignedUrl;

  @JsonKey(name: 'presigned_url_expiration')
  final DateTime? presignedUrlExpiration;

  @JsonKey(name: 'duration_ms')
  final int durationMs;

  @JsonKey(name: 'waveform_percentages')
  final List<double> waveformPercentages;

  @JsonKey(name: 'language', defaultValue: 'unknown')
  final String? language;

  @JsonKey(name: 'is_original_audio', defaultValue: true)
  final bool? isOriginalAudio;

  @JsonKey(name: 'extension', defaultValue: 'mp3')
  final String? extension;

  Map<String, dynamic> toJson() => _$AudioModelDtoToJson(this);
}
