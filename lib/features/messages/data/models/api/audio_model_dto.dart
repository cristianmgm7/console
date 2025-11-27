/// DTO for audio model in message
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

  final String id;
  final String url;
  final bool streaming;
  final String language;
  final int durationMs;
  final List<double> waveformPercentages;
  final bool isOriginalAudio;
  final String extension;

  factory AudioModelDto.fromJson(Map<String, dynamic> json) {
    return AudioModelDto(
      id: json['_id'] as String,
      url: json['url'] as String,
      streaming: json['streaming'] as bool,
      language: json['language'] as String,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      waveformPercentages: (json['waveform_percentages'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      isOriginalAudio: json['is_original_audio'] as bool,
      extension: json['extension'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'url': url,
      'streaming': streaming,
      'language': language,
      'duration_ms': durationMs,
      'waveform_percentages': waveformPercentages,
      'is_original_audio': isOriginalAudio,
      'extension': extension,
    };
  }
}
