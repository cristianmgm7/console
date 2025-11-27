import 'package:equatable/equatable.dart';

/// Domain entity representing a timecode segment in a transcript
class Timecode extends Equatable {
  const Timecode({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  final String text;
  final Duration startTime;
  final Duration endTime;

  @override
  List<Object?> get props => [text, startTime, endTime];
}
