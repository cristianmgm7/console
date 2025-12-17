import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_location.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for conversation attachment
class ConversationAttachment extends Equatable {
  const ConversationAttachment({
    this.id,
    this.clientId,
    this.creatorId,
    this.createdAt,
    this.type,
    this.link,
    this.activeBegin,
    this.activeEnd,
    this.filename,
    this.mimeType,
    this.lengthInBytes,
    this.location,
  });

  final String? id;
  final String? clientId;
  final String? creatorId;
  final String? createdAt;
  final String? type;
  final String? link;
  final String? activeBegin;
  final String? activeEnd;
  final String? filename;
  final String? mimeType;
  final int? lengthInBytes;
  final ConversationLocation? location;

  @override
  List<Object?> get props => [
    id,
    clientId,
    creatorId,
    createdAt,
    type,
    link,
    activeBegin,
    activeEnd,
    filename,
    mimeType,
    lengthInBytes,
    location,
  ];
}
