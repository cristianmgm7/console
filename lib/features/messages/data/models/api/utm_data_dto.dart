/// DTO for UTM data in message
class UtmDataDto {
  const UtmDataDto({
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
  });

  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmTerm;
  final String? utmContent;

  factory UtmDataDto.fromJson(Map<String, dynamic> json) {
    return UtmDataDto(
      utmSource: json['utm_source'] as String?,
      utmMedium: json['utm_medium'] as String?,
      utmCampaign: json['utm_campaign'] as String?,
      utmTerm: json['utm_term'] as String?,
      utmContent: json['utm_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (utmSource != null) 'utm_source': utmSource,
      if (utmMedium != null) 'utm_medium': utmMedium,
      if (utmCampaign != null) 'utm_campaign': utmCampaign,
      if (utmTerm != null) 'utm_term': utmTerm,
      if (utmContent != null) 'utm_content': utmContent,
    };
  }
}
