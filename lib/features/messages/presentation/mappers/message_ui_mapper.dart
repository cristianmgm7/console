import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Extension methods to convert domain entities to UI models
extension MessageUiMapper on Message {
  /// Gets the URL of the MP3 audio if available
  static String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    try {
      final mp3Audio = audioModels.firstWhere(
        (audio) => audio.format == 'mp3',
      );
      return mp3Audio.url;
    } catch (_) {
      // No MP3 found
      return null;
    }
  }
  /// Creates a UI model with optional user enrichment
  MessageUiModel toUiModel([User? creator]) {
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
      // User profile data
      creator: creator,
      // Computed UI properties
      conversationId: channelIds.isNotEmpty ? channelIds.first : '',
      userId: creatorId,
      text: notes.isNotEmpty ? notes : null,
      transcriptText: textModels.isNotEmpty ? textModels.first.text : null,
      audioUrl: audioModels.isNotEmpty ? _getPlayableAudioUrl(audioModels) : null,
    );
  }
}
