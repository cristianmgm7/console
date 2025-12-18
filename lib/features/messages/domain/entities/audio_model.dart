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
    this.presignedUrl,
    this.presignedUrlExpiration,
  });

  final String id;
  final String url;
  final String? presignedUrl;
  final DateTime? presignedUrlExpiration;
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
    presignedUrl,
    presignedUrlExpiration,
    isStreaming,
    language,
    duration,
    waveformData,
    isOriginal,
    format,
  ];
}
