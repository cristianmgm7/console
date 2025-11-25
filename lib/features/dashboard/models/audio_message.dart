class AudioMessage {

  AudioMessage({
    required this.id,
    required this.date,
    required this.owner,
    required this.message,
    required this.duration,
    required this.status,
    required this.project,
  });
  
  final String id;
  final DateTime date;
  final String owner;
  final String message;
  final Duration duration;
  final String status;
  final String project;
}
