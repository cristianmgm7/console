import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/reaction_summary_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/timecode_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_detail_dto.g.dart';

// Custom converter for ReactionSummaryDto that handles null values
class ReactionSummaryDtoConverter implements JsonConverter<ReactionSummaryDto, Map<String, dynamic>?> {
  const ReactionSummaryDtoConverter();

  @override
  ReactionSummaryDto fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReactionSummaryDto();
    return ReactionSummaryDto.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(ReactionSummaryDto object) => object.toJson();
}

/// DTO for message detail from API response
/// This DTO represents the direct response from the message endpoint
/// without requiring complex normalization
@JsonSerializable()
class MessageDetailDto {
  const MessageDetailDto({
    this.id,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.conversationId,
    this.workspaceId,
    this.creatorId,
    this.status,
    this.usersCaughtUp,
    this.reactionSummary,
    this.language,
    this.availableLanguages,
    this.isOriginalLanguage,
    this.transcript,
    this.aiSummary,
    this.link,
    this.timeCodes,
    this.conversationSequence,
    this.audio,
    this.parentMessageId,
  });

  factory MessageDetailDto.fromJson(Map<String, dynamic> json) => _$MessageDetailDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'conversation_id')
  final String? conversationId;

  @JsonKey(name: 'workspace_id')
  final String? workspaceId;

  @JsonKey(name: 'creator_id')
  final String? creatorId;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'parent_message_id')
  final String? parentMessageId;

  @JsonKey(name: 'language')
  final String? language;

  @JsonKey(name: 'available_languages')
  final List<String>? availableLanguages;

  @JsonKey(name: 'is_original_language')
  final bool? isOriginalLanguage;

  @JsonKey(name: 'transcript')
  final String? transcript;

  @JsonKey(name: 'ai_summary')
  final String? aiSummary;

  @JsonKey(name: 'link')
  final String? link;

  @JsonKey(name: 'time_codes')
  final List<TimecodeDto>? timeCodes;

  @JsonKey(name: 'conversation_sequence')
  final int? conversationSequence;

  @JsonKey(name: 'audio')
  final AudioModelDto? audio;

  @JsonKey(name: 'users_caught_up')
  final String? usersCaughtUp;

  @ReactionSummaryDtoConverter()
  @JsonKey(name: 'reaction_summary')
  final ReactionSummaryDto? reactionSummary;

  Map<String, dynamic> toJson() => _$MessageDetailDtoToJson(this);
}
