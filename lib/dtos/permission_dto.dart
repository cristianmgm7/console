import 'package:json_annotation/json_annotation.dart';

part 'permission_dto.g.dart';

/// DTO for individual permissions with value and reason
@JsonSerializable()
class PermissionDto {
  const PermissionDto({
    required this.value,
    required this.reason,
  });

  factory PermissionDto.fromJson(Map<String, dynamic> json) =>
      _$PermissionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionDtoToJson(this);

  final bool value;
  final String reason;
}
