import 'package:equatable/equatable.dart';

/// Domain entity representing an audio model
class AudioModel extends Equatable {
  const AudioModel({
    required this.id,
    required this.url,
    required this.isStreaming,
    required this.language,
    required this.duration,
    required this.waveformData,
    required this.isOriginal,
    required this.format,
  });

  final String id;
  final String url;
  final bool isStreaming;
  final String language;
  final Duration duration;
  final List<double> waveformData;
  final bool isOriginal;
  final String format;

  @override
  List<Object?> get props => [
        id,
        url,
        isStreaming,
        language,
        duration,
        waveformData,
        isOriginal,
        format,
      ];
}
