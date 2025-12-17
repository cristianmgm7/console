import 'package:equatable/equatable.dart';

/// Domain entity for user stats
class ConversationUserStats extends Equatable {
  const ConversationUserStats({
    this.userId,
    this.totalMessagesPosted,
    this.totalSentMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalHeardMessages,
    this.totalUnheardMessages,
  });

  final String? userId;
  final int? totalMessagesPosted;
  final int? totalSentMilliseconds;
  final int? totalHeardMilliseconds;
  final int? totalEngagedPercentage;
  final int? totalHeardMessages;
  final int? totalUnheardMessages;

  @override
  List<Object?> get props => [
    userId,
    totalMessagesPosted,
    totalSentMilliseconds,
    totalHeardMilliseconds,
    totalEngagedPercentage,
    totalHeardMessages,
    totalUnheardMessages,
  ];
}
