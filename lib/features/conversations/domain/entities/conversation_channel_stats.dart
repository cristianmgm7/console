import 'package:equatable/equatable.dart';

/// Domain entity for channel stats
class ConversationChannelStats extends Equatable {
  const ConversationChannelStats({
    this.totalDurationMilliseconds,
    this.totalHeardMilliseconds,
    this.totalEngagedPercentage,
    this.totalMessagesPosted,
    this.totalUsers,
  });

  final int? totalDurationMilliseconds;
  final int? totalHeardMilliseconds;
  final int? totalEngagedPercentage;
  final int? totalMessagesPosted;
  final int? totalUsers;

  @override
  List<Object?> get props => [
    totalDurationMilliseconds,
    totalHeardMilliseconds,
    totalEngagedPercentage,
    totalMessagesPosted,
    totalUsers,
  ];
}
