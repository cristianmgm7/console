import 'package:json_annotation/json_annotation.dart';

part 'utm_data_dto.g.dart';

/// DTO for UTM data in message
@JsonSerializable()
class UtmDataDto {
  const UtmDataDto({
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
  });

  @JsonKey(name: 'utm_source')
  final String? utmSource;

  @JsonKey(name: 'utm_medium')
  final String? utmMedium;

  @JsonKey(name: 'utm_campaign')
  final String? utmCampaign;

  @JsonKey(name: 'utm_term')
  final String? utmTerm;

  @JsonKey(name: 'utm_content')
  final String? utmContent;

  factory UtmDataDto.fromJson(Map<String, dynamic> json) => _$UtmDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UtmDataDtoToJson(this);
}
