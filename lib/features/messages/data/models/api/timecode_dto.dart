/// DTO for timecode in text model
// ignore_for_file: sort_constructors_first

class TimecodeDto {
  const TimecodeDto({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final int start;
  final int end;

  factory TimecodeDto.fromJson(Map<String, dynamic> json) {
    return TimecodeDto(
      text: json['t'] as String,
      start: (json['s'] as num?)?.toInt() ?? 0,
      end: (json['e'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      't': text,
      's': start,
      'e': end,
    };
  }
}
