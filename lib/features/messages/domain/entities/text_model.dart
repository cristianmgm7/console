import 'package:carbon_voice_console/features/messages/domain/entities/timecode.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing a text model
class TextModel extends Equatable {
  const TextModel({
    required this.type,
    required this.audioId,
    required this.language,
    required this.text,
    required this.timecodes,
  });

  final String type;
  final String audioId;
  final String language;
  final String text;
  final List<Timecode> timecodes;

  @override
  List<Object?> get props => [type, audioId, language, text, timecodes];
}
