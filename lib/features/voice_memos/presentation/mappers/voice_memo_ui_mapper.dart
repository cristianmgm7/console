import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension VoiceMemoUiMapper on VoiceMemo {
  /// Gets the URL of the MP3 audio if available
  static String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    try {
      final mp3Audio = audioModels.firstWhere(
        (audio) => audio.format == 'mp3',
      );
      return mp3Audio.presignedUrl ?? mp3Audio.url;
    } on StateError {
      return audioModels.first.presignedUrl ?? audioModels.first.url;
    }
  }

  /// Gets the summary text if available
  static String? _getSummary(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    try {
      final summary = textModels.firstWhere(
        (model) => model.type.toLowerCase() == 'summary',
      );
      return summary.text.isNotEmpty ? summary.text : null;
    } on StateError {
      return null;
    }
  }

  /// Gets the transcript text if available
  static String? _getTranscript(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    try {
      final transcript = textModels.firstWhere(
        (model) => model.type.toLowerCase() == 'transcript',
      );
      return transcript.text.isNotEmpty ? transcript.text : null;
    } on StateError {
      return textModels.first.text.isNotEmpty ? textModels.first.text : null;
    }
  }

  /// Converts domain entity to UI model
  VoiceMemoUiModel toUiModel() {
    return VoiceMemoUiModel(
      id: id,
      creatorId: creatorId,
      createdAt: createdAt,
      deletedAt: deletedAt,
      duration: duration,
      notes: notes,
      name: name,
      status: status,
      type: type,
      audioModels: audioModels,
      textModels: textModels,
      folderId: folderId,
      summary: _getSummary(textModels),
      transcript: _getTranscript(textModels),
      audioUrl: _getPlayableAudioUrl(audioModels),
    );
  }
}
