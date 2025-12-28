import 'package:json_annotation/json_annotation.dart';

part 'session_dto.g.dart';

@JsonSerializable()
class SessionDto {

  SessionDto({
    required this.id,
    required this.appName,
    required this.userId,
    required this.state,
    required this.events,
    required this.lastUpdateTime,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);
  final String id;
  final String appName;
  final String userId;
  final Map<String, dynamic> state;
  final List<dynamic> events;
  final double lastUpdateTime;

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);
}
