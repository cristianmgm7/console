import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// UI model for voice memo presentation
/// Contains computed properties optimized for UI rendering
class VoiceMemoUiModel extends Equatable {
  const VoiceMemoUiModel({
    required this.id,
    required this.creatorId,
    required this.createdAt,
    required this.duration,
    required this.notes,
    required this.status,
    required this.type,
    required this.audioModels,
    required this.textModels,
    this.deletedAt,
    this.name,
    this.folderId,
    this.summary,
    this.transcript,
    this.audioUrl,
  });

  final String id;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final Duration duration;
  final String notes;
  final String? name;
  final String status;
  final String type;
  final List<AudioModel> audioModels;
  final List<TextModel> textModels;
  final String? folderId;

  // Computed UI properties
  final String? summary;
  final String? transcript;
  final String? audioUrl;

  // Computed getters
  bool get hasPlayableAudio => audioModels.any((audio) => audio.format == 'mp3');

  AudioModel? get playableAudioModel {
    if (audioModels.isEmpty) return null;
    try {
      return audioModels.firstWhere(
        (audio) => audio.format == 'mp3',
      );
    } on StateError {
      return audioModels.first;
    }
  }

  String get displayText => summary ?? transcript ?? notes;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
    id,
    creatorId,
    createdAt,
    deletedAt,
    duration,
    notes,
    name,
    status,
    type,
    audioModels,
    textModels,
    folderId,
    summary,
    transcript,
    audioUrl,
  ];
}
