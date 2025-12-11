import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:equatable/equatable.dart';

/// Complete data needed for the preview composer screen
/// Contains conversation details and selected messages
class PreviewComposerData extends Equatable {
  const PreviewComposerData({
    required this.conversation,
    required this.selectedMessages,
    required this.initialMetadata,
  });

  final Conversation conversation;
  final List<Message> selectedMessages;
  final PreviewMetadata initialMetadata;

  @override
  List<Object?> get props => [conversation, selectedMessages, initialMetadata];
}
