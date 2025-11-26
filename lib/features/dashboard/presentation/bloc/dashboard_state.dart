import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:equatable/equatable.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading initial dashboard data
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard data loaded successfully
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.workspaces,
    required this.selectedWorkspace,
    required this.conversations,
    required this.selectedConversationIds, // Multi-select support
    required this.messages,
    required this.users, // userId -> User
    required this.conversationColorMap, // conversationId -> colorIndex
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  });

  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final List<Conversation> conversations;
  final Set<String> selectedConversationIds; // Multi-select support
  final List<Message> messages;
  final Map<String, User> users; // userId -> User
  final Map<String, int> conversationColorMap; // conversationId -> colorIndex
  final bool isLoadingMore;
  final bool hasMoreMessages;

  @override
  List<Object?> get props => [
        workspaces,
        selectedWorkspace,
        conversations,
        selectedConversationIds,
        messages,
        users,
        conversationColorMap,
        isLoadingMore,
        hasMoreMessages,
      ];

  DashboardLoaded copyWith({
    List<Workspace>? workspaces,
    Workspace? selectedWorkspace,
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    List<Message>? messages,
    Map<String, User>? users,
    Map<String, int>? conversationColorMap,
    bool? isLoadingMore,
    bool? hasMoreMessages,
  }) {
    return DashboardLoaded(
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspace: selectedWorkspace ?? this.selectedWorkspace,
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      messages: messages ?? this.messages,
      users: users ?? this.users,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
    );
  }
}

/// Error occurred while loading dashboard data
class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}


