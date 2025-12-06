import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_summary_item.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for conversation summary
class ConversationSummary extends Equatable {
  const ConversationSummary({
    this.channelId,
    this.spanId,
    this.items,
  });

  final String? channelId;
  final String? spanId;
  final List<ConversationSummaryItem>? items;

  @override
  List<Object?> get props => [channelId, spanId, items];
}
