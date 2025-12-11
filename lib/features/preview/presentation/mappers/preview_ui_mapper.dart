import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Extension methods to create preview UI models from domain entities
extension PreviewUiMapper on Conversation {
  /// Creates a preview UI model from conversation, messages, and user data
  ///
  /// [messages] - Selected messages to include in preview
  /// [userMap] - Map of userId -> User for enrichment
  PreviewUiModel toPreviewUiModel(
    List<Message> messages,
    Map<String, User> userMap,
  ) {
    // Calculate total duration from selected messages
    final totalDuration = messages.fold<Duration>(
      Duration.zero,
      (sum, message) => sum + message.duration,
    );

    // Get unique participants from conversation collaborators
    final participantsList = _mapParticipants(userMap);

    // Map messages with creator info
    final previewMessages = messages.map((message) {
      return _mapMessage(message, userMap);
    }).toList();

    return PreviewUiModel(
      conversationName: channelName ?? 'Unknown Conversation',
      conversationDescription: description ?? '',
      conversationCoverUrl: imageUrl,
      participants: participantsList,
      messageCount: messages.length,
      totalDuration: totalDuration,
      totalDurationFormatted: _formatDuration(totalDuration),
      messages: previewMessages,
    );
  }

  /// Maps conversation collaborators to preview participants
  List<PreviewParticipant> _mapParticipants(Map<String, User> userMap) {
    if (collaborators == null || collaborators!.isEmpty) {
      return [];
    }

    return collaborators!.map((collaborator) {
      // Try to get user from map, fallback to collaborator data
      final user = userMap[collaborator.userGuid];
      final fallbackName = '${collaborator.firstName ?? ''} ${collaborator.lastName ?? ''}'.trim();
      final fullName = (user?.fullName ?? fallbackName).trim();
      final id = collaborator.userGuid ?? 'unknown-user';
      return PreviewParticipant(
        id: id,
        fullName: fullName.isEmpty ? id : fullName,
        avatarUrl: user?.avatarUrl ?? collaborator.imageUrl,
      );
    }).toList();
  }

  /// Maps a message to preview message with creator info
  PreviewMessage _mapMessage(Message message, Map<String, User> userMap) {
    final creator = userMap[message.creatorId];

    return PreviewMessage(
      id: message.id,
      creatorName: creator?.fullName ?? message.creatorId,
      creatorAvatarUrl: creator?.avatarUrl,
      createdAt: message.createdAt,
      createdAtFormatted: _formatDateTime(message.createdAt),
      duration: message.duration,
      durationFormatted: _formatDuration(message.duration),
      summary: _getMessageText(message.textModels),
      audioUrl: _getPlayableAudioUrl(message.audioModels),
    );
  }

  /// Formats duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats datetime as "MM/DD/YY h:mm A"
  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString().substring(2);
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  /// Gets summary or transcript text from message
  String? _getMessageText(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    // Priority: summary > transcription > first text
    final summary = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'summary',
      orElse: () => null,
    );
    if (summary != null && summary.text.isNotEmpty) return summary.text;

    final transcription = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'transcription',
      orElse: () => null,
    );
    if (transcription != null && transcription.text.isNotEmpty) {
      return transcription.text;
    }

    return textModels.first.text.isNotEmpty ? textModels.first.text : null;
  }

  /// Gets playable audio URL (MP3 preferred)
  String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    final mp3Audio = audioModels.firstWhere(
      (audio) => audio.format == 'mp3',
      orElse: () => audioModels.first,
    );
    return mp3Audio.presignedUrl ?? mp3Audio.url;
  }
}
