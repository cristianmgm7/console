import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension MessageUiMapper on Message {
  MessageUiModel toUiModel() {
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
      // Computed UI properties
      conversationId: channelIds.isNotEmpty ? channelIds.first : '',
      userId: creatorId,
      text: notes.isNotEmpty ? notes : null,
      transcriptText: textModels.isNotEmpty ? textModels.first.text : null,
      audioUrl: audioModels.isNotEmpty ? audioModels.first.url : null,
    );
  }
}
