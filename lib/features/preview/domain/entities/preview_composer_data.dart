import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/presentation/mappers/preview_ui_mapper.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
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

/// Extension to convert PreviewComposerData to UI state
extension PreviewComposerDataMapper on PreviewComposerData {
  /// Converts the composer data to a PreviewUiModel for UI display
  /// [userMap] - Map of userId -> User for enrichment
  PreviewUiModel toPreviewUiModel(Map<String, User> userMap) {
    return conversation.toPreviewUiModel(selectedMessages, userMap);
  }

  /// Checks if the metadata is valid for publishing
  bool get isMetadataValid =>
      initialMetadata.title.trim().isNotEmpty &&
      initialMetadata.description.trim().isNotEmpty;
}
