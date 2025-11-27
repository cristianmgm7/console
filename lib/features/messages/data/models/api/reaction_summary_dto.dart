/// DTO for reaction summary in message
class ReactionSummaryDto {
  const ReactionSummaryDto({
    required this.reactionCounts,
    required this.topUserReactions,
  });

  final Map<String, dynamic> reactionCounts;
  final List<dynamic> topUserReactions;

  factory ReactionSummaryDto.fromJson(Map<String, dynamic> json) {
    return ReactionSummaryDto(
      reactionCounts: json['reaction_counts'] as Map<String, dynamic>? ?? {},
      topUserReactions: json['top_user_reactions'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reaction_counts': reactionCounts,
      'top_user_reactions': topUserReactions,
    };
  }
}
