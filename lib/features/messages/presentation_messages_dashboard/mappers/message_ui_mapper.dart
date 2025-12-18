import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension MessageUiMapper on Message {
  /// Gets the URL of the MP3 audio if available
  static String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    final mp3Audio = audioModels.firstWhere(
      (audio) => audio.format == 'mp3',
      orElse: () => audioModels.first,
    );
    return mp3Audio.presignedUrl ?? mp3Audio.url;
  }

  /// Gets the message text to display, prioritizing summary over transcription
  /// Returns summary if available, otherwise falls back to transcription
  static String? _getMessageText(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    // Try to find summary first
    final summary = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'summary',
      orElse: () => null,
    );
    if (summary != null && summary.text.isNotEmpty) return summary.text;

    // Fall back to transcription
    final transcription = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'transcription',
      orElse: () => null,
    );
    if (transcription != null && transcription.text.isNotEmpty) {
      return transcription.text;
    }

    // Last resort: return the first text model's text if not empty
    return textModels.first.text.isNotEmpty ? textModels.first.text : null;
  }

  /// Creates a UI model with optional participant enrichment
  MessageUiModel toUiModel([ConversationCollaborator? participant]) {
    return MessageUiModel(
      // Original message properties
      id: id,
      creatorId: creatorId,
      createdAt: createdAt,
      workspaceIds: workspaceIds,
      channelIds: channelIds,
      duration: duration,
      audioModels: audioModels,
      textModels: textModels,
      status: status,
      type: type,
      lastHeardAt: lastHeardAt,
      heardDuration: heardDuration,
      totalHeardDuration: totalHeardDuration,
      isTextMessage: isTextMessage,
      notes: notes,
      lastUpdatedAt: lastUpdatedAt,
      parentMessageId: parentMessageId,
      // Participant data
      participant: participant,
      // Computed UI properties
      conversationId: channelIds.isNotEmpty ? channelIds.first : '',
      userId: creatorId,
      text: notes.isNotEmpty ? notes : _getMessageText(textModels),
      transcriptText: textModels.isNotEmpty ? textModels.first.text : null,
      audioUrl: audioModels.isNotEmpty ? _getPlayableAudioUrl(audioModels) : null,
    );
  }
}
