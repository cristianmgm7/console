import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_avatar.dart';
import 'package:equatable/equatable.dart';


/// Domain entity for conversation avatars
class ConversationAvatars extends Equatable {
  const ConversationAvatars({
    this.avatars,
    this.numRows,
    this.numColumns,
  });

  final List<ConversationAvatar>? avatars;
  final int? numRows;
  final int? numColumns;

  @override
  List<Object?> get props => [avatars, numRows, numColumns];
}
