import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:equatable/equatable.dart';

/// Complete data needed for the preview composer screen
/// Contains conversation details and selected messages
class PreviewComposerData extends Equatable {
  const PreviewComposerData({
    required this.conversation,
    required this.selectedMessages,
  });

  final Conversation conversation;
  final List<Message> selectedMessages;

  @override 
  List<Object?> get props => [conversation, selectedMessages];
}
