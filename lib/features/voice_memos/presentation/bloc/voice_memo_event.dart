import 'package:equatable/equatable.dart';

sealed class VoiceMemoEvent extends Equatable {
  const VoiceMemoEvent();

  @override
  List<Object?> get props => [];
}

/// Load voice memos from repository
class LoadVoiceMemos extends VoiceMemoEvent {
  const LoadVoiceMemos({
    this.workspaceId,
    this.folderId,
    this.forceRefresh = false,
  });

  final String? workspaceId;
  final String? folderId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [workspaceId, folderId, forceRefresh];
}
