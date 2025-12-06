import 'package:equatable/equatable.dart';

/// Domain entity for summary item
class ConversationSummaryItem extends Equatable {
  const ConversationSummaryItem({
    this.userId,
    this.text,
    this.type,
  });

  final String? userId;
  final String? text;
  final String? type;

  @override
  List<Object?> get props => [userId, text, type];
}
