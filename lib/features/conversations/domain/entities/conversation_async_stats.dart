import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_channel_stats.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_user_stats.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for async stats
class ConversationAsyncStats extends Equatable {
  const ConversationAsyncStats({
    this.channelStats,
    this.userStats,
  });

  final ConversationChannelStats? channelStats;
  final List<ConversationUserStats>? userStats;

  @override
  List<Object?> get props => [channelStats, userStats];
}
