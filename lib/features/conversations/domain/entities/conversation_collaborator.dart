import 'package:equatable/equatable.dart';

/// Domain entity for conversation collaborator
class ConversationCollaborator extends Equatable {
  const ConversationCollaborator({
    this.userGuid,
    this.imageUrl,
    this.firstName,
    this.lastName,
    this.permission,
    this.joined,
    this.lastPosted,
    this.firstAccessedAt,
    this.lastViewedAt,
    this.status,
    this.primaryLanguage,
  });

  final String? userGuid;
  final String? imageUrl;
  final String? firstName;
  final String? lastName;
  final String? permission;
  final String? joined;
  final String? lastPosted;
  final String? firstAccessedAt;
  final String? lastViewedAt;
  final String? status;
  final String? primaryLanguage;

  @override
  List<Object?> get props => [
    userGuid,
    imageUrl,
    firstName,
    lastName,
    permission,
    joined,
    lastPosted,
    firstAccessedAt,
    lastViewedAt,
    status,
    primaryLanguage,
  ];
}
