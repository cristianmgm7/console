import 'package:equatable/equatable.dart';

/// Domain entity for channel span
class ConversationChannelSpan extends Equatable {
  const ConversationChannelSpan({
    this.id,
    this.begin,
    this.end,
    this.deletedAt,
    this.requiredUsers,
    this.type,
    this.topic,
  });

  final String? id;
  final String? begin;
  final String? end;
  final String? deletedAt;
  final List<String>? requiredUsers;
  final String? type;
  final String? topic;

  @override
  List<Object?> get props => [id, begin, end, deletedAt, requiredUsers, type, topic];
}
