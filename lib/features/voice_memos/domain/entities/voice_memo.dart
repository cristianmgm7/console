import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for Voice Memo
class VoiceMemo extends Equatable {
  const VoiceMemo({
    required this.id,
    required this.creatorId,
    required this.createdAt,
    required this.workspaceIds,
    required this.channelIds,
    required this.duration,
    required this.audioModels,
    required this.textModels,
    required this.status,
    required this.type,
    required this.isTextMessage,
    required this.notes,
    this.deletedAt,
    this.lastUpdatedAt,
    this.parentMessageId,
    this.heardMs,
    this.name,
    this.folderId,
    this.lastHeardAt,
    this.totalHeardMs,
  });

  final String id;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime? lastUpdatedAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final String? parentMessageId;
  final int? heardMs;
  final String notes;
  final String? name;
  final bool isTextMessage;
  final String status;
  final String type;
  final List<AudioModel> audioModels; // Reuses existing AudioModel from messages
  final List<TextModel> textModels; // Reuses existing TextModel from messages
  final String? folderId;
  final DateTime? lastHeardAt;
  final int? totalHeardMs;
  final Duration duration;

  @override
  List<Object?> get props => [
    id,
    creatorId,
    createdAt,
    deletedAt,
    lastUpdatedAt,
    workspaceIds,
    channelIds,
    parentMessageId,
    heardMs,
    notes,
    name,
    isTextMessage,
    status,
    type,
    audioModels,
    textModels,
    folderId,
    lastHeardAt,
    totalHeardMs,
    duration,
  ];
}
