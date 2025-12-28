import 'package:json_annotation/json_annotation.dart';

part 'event_dto.g.dart';

@JsonSerializable()
class EventDto {

  EventDto({
    required this.id,
    required this.invocationId,
    required this.author,
    required this.timestamp,
    required this.content,
    this.actions,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  final String id;
  final String invocationId;
  final String author;
  final double timestamp;
  final ContentDto content;
  final ActionsDto? actions;

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
}

@JsonSerializable()
class ContentDto {

  ContentDto({
    required this.role,
    required this.parts,
  });

  factory ContentDto.fromJson(Map<String, dynamic> json) =>
      _$ContentDtoFromJson(json);
  final String role;
  final List<PartDto> parts;

  Map<String, dynamic> toJson() => _$ContentDtoToJson(this);
}

@JsonSerializable()
class PartDto {

  PartDto({
    this.text,
    this.functionCall,
    this.functionResponse,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) =>
      _$PartDtoFromJson(json);
  final String? text;
  final FunctionCallDto? functionCall;
  final FunctionResponseDto? functionResponse;

  Map<String, dynamic> toJson() => _$PartDtoToJson(this);
}

@JsonSerializable()
class FunctionCallDto {

  FunctionCallDto({
    required this.id,
    required this.name,
    required this.args,
  });

  factory FunctionCallDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallDtoFromJson(json);
  final String id;
  final String name;
  final Map<String, dynamic> args;

  Map<String, dynamic> toJson() => _$FunctionCallDtoToJson(this);
}

@JsonSerializable()
class FunctionResponseDto {

  FunctionResponseDto({
    required this.id,
    required this.name,
    required this.response,
  });

  factory FunctionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseDtoFromJson(json);
  final String id;
  final String name;
  final Map<String, dynamic> response;

  Map<String, dynamic> toJson() => _$FunctionResponseDtoToJson(this);
}

@JsonSerializable()
class ActionsDto {

  ActionsDto({
    this.stateDelta,
    this.artifactDelta,
  });

  factory ActionsDto.fromJson(Map<String, dynamic> json) =>
      _$ActionsDtoFromJson(json);

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;

  Map<String, dynamic> toJson() => _$ActionsDtoToJson(this);
}
