import 'package:json_annotation/json_annotation.dart';

part 'audio_model_dto.g.dart';

/// DTO for audio model in message
@JsonSerializable()
class AudioModelDto {
  const AudioModelDto({
    required this.url, required this.durationMs, required this.waveformPercentages, this.id,
    this.streamingUrl,
    this.presignedUrl,
    this.presignedUrlExpiration,
    this.language,
    this.isOriginalAudio,
    this.extension,
    this.streaming,
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

  @JsonKey(name: 'streaming', defaultValue: true)
  final bool? streaming;

  /// Computed property indicating if this audio can be streamed
  /// Uses the streaming field if available, otherwise checks streamingUrl
  bool get canStream => streaming ?? (streamingUrl != null);

  Map<String, dynamic> toJson() => _$AudioModelDtoToJson(this);
}
