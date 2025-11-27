import 'package:json_annotation/json_annotation.dart';

part 'reaction_summary_dto.g.dart';

/// DTO for reaction summary in message
@JsonSerializable()
class ReactionSummaryDto {
  const ReactionSummaryDto({
    required this.reactionCounts,
    required this.topUserReactions,
  });

  @JsonKey(name: 'reaction_counts')
  final Map<String, dynamic> reactionCounts;

  @JsonKey(name: 'top_user_reactions')
  final List<dynamic> topUserReactions;

  factory ReactionSummaryDto.fromJson(Map<String, dynamic> json) => _$ReactionSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionSummaryDtoToJson(this);
}
