import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when dashboard screen is loaded
class DashboardInitialized extends DashboardEvent {
  const DashboardInitialized();
}

/// Triggered when user selects a different workspace
class WorkspaceSelected extends DashboardEvent {
  const WorkspaceSelected(this.workspaceId);

  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}

/// Triggered when user toggles a conversation selection (multi-select)
class ConversationToggled extends DashboardEvent {
  const ConversationToggled(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Triggered when user selects multiple conversations at once
class MultipleConversationsSelected extends DashboardEvent {
  const MultipleConversationsSelected(this.conversationIds);

  final Set<String> conversationIds;

  @override
  List<Object?> get props => [conversationIds];
}

/// Triggered when user clears all conversation selections
class ConversationSelectionCleared extends DashboardEvent {
  const ConversationSelectionCleared();
}

/// Triggered when user wants to load more messages (pagination)
class LoadMoreMessages extends DashboardEvent {
  const LoadMoreMessages();
}

/// Triggered when user wants to refresh data
class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}
