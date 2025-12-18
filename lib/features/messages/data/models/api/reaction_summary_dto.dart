import 'package:json_annotation/json_annotation.dart';

part 'reaction_summary_dto.g.dart';

/// DTO for reaction summary in message
@JsonSerializable()
class ReactionSummaryDto {
  const ReactionSummaryDto({
    this.reactionCounts = const {},
    this.topUserReactions = const [],
  });

  factory ReactionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ReactionSummaryDtoFromJson(json);

  @JsonKey(name: 'reaction_counts', defaultValue: {})
  final Map<String, dynamic> reactionCounts;

  @JsonKey(name: 'top_user_reactions', defaultValue: [])
  final List<dynamic> topUserReactions;

  Map<String, dynamic> toJson() => _$ReactionSummaryDtoToJson(this);
}
