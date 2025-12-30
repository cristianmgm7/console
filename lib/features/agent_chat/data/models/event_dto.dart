import 'package:json_annotation/json_annotation.dart';

part 'event_dto.g.dart';

@JsonSerializable()
class EventDto {

  EventDto({
    required this.author, 
    required this.content, 
    this.id,
    this.invocationId,
    this.timestamp,
    this.actions,
    this.longRunningToolIds,
    this.branch,
    this.partial,
    this.modelVersion,
    this.finishReason,
    this.usageMetadata,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  final String? id;
  final String? invocationId;
  final String author;
  final double? timestamp;
  final ContentDto content;
  final Map<String, dynamic>? actions;
  final List<String>? longRunningToolIds;
  final String? branch;
  final bool? partial;
  final String? modelVersion;
  final String? finishReason;
  final Map<String, dynamic>? usageMetadata;

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
    this.inlineData,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) =>
      _$PartDtoFromJson(json);
  final String? text;
  final InlineDataDto? inlineData;

  Map<String, dynamic> toJson() => _$PartDtoToJson(this);
}

@JsonSerializable()
class InlineDataDto {
  InlineDataDto({
    required this.mimeType,
    required this.data,
  });

  factory InlineDataDto.fromJson(Map<String, dynamic> json) =>
      _$InlineDataDtoFromJson(json);

  final String mimeType;
  final String data;

  Map<String, dynamic> toJson() => _$InlineDataDtoToJson(this);
}
