import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(
    this._workspaceRepository,
    this._conversationRepository,
    this._messageRepository,
    this._userRepository,
    this._logger,
  ) : super(const DashboardInitial()) {
    on<DashboardInitialized>(_onDashboardLoaded);
    on<WorkspaceSelected>(_onWorkspaceSelected);
    on<ConversationToggled>(_onConversationToggled);
    on<MultipleConversationsSelected>(_onMultipleConversationsSelected);
    on<ConversationSelectionCleared>(_onConversationSelectionCleared);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<DashboardRefreshed>(_onDashboardRefreshed);
  }

  final WorkspaceRepository _workspaceRepository;
  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  static const int _messagesPerPage = 50;
  int _currentMessageStart = 0;

  Future<void> _onDashboardLoaded(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      // Step 1: Load workspaces
      final workspacesResult = await _workspaceRepository.getWorkspaces();

      await workspacesResult.fold(
        onSuccess: (workspaces) async {
          if (workspaces.isEmpty) {
            emit(const DashboardError('No workspaces found'));
            return;
          }

          // Step 2: Auto-select first workspace
          final selectedWorkspace = workspaces.first;
          _logger.i('Auto-selected workspace: ${selectedWorkspace.name}');

          // Step 3: Load conversations for selected workspace
          final conversationsResult = await _conversationRepository.getConversations(
            selectedWorkspace.id,
          );

          await conversationsResult.fold(
            onSuccess: (conversations) async {
              if (conversations.isEmpty) {
                emit(DashboardLoaded(
                  workspaces: workspaces,
                  selectedWorkspace: selectedWorkspace,
                  conversations: const [],
                  selectedConversationIds: const {},
                  messages: const [],
                  users: const {},
                  conversationColorMap: const {},
                ),);
                return;
              }

              // Step 4: Auto-select first conversation
              final selectedConversation = conversations.first;
              _logger.i('Auto-selected conversation: ${selectedConversation.name}');

              // Step 5: Load recent messages
              _currentMessageStart = 0;
              final messagesResult = await _messageRepository.getRecentMessages(
                conversationId: selectedConversation.id,
              );

              await messagesResult.fold(
                onSuccess: (messages) async {
                  // Step 6: Load users for messages
                  final userIds = messages.map((m) => m.userId).toSet().toList();
                  final usersResult = await _userRepository.getUsers(userIds);

                  // Create color map for conversations
                  final colorMap = <String, int>{};
                  for (final conversation in conversations) {
                    if (conversation.colorIndex != null) {
                      colorMap[conversation.id] = conversation.colorIndex!;
                    }
                  }

                  usersResult.fold(
                    onSuccess: (users) {
                      final userMap = {for (final u in users) u.id: u};

                      emit(DashboardLoaded(
                        workspaces: workspaces,
                        selectedWorkspace: selectedWorkspace,
                        conversations: conversations,
                        selectedConversationIds: {selectedConversation.id}, // Multi-select with one
                        messages: messages,
                        users: userMap,
                        conversationColorMap: colorMap,
                      ),);
                    },
                    onFailure: (failure) {
                      // Still show messages even if user loading fails
                      _logger.w('Failed to load users: ${failure.failure}');
                      emit(DashboardLoaded(
                        workspaces: workspaces,
                        selectedWorkspace: selectedWorkspace,
                        conversations: conversations,
                        selectedConversationIds: {selectedConversation.id},
                        messages: messages,
                        users: const {},
                        conversationColorMap: colorMap,
                      ),);
                    },
                  );
                },
                onFailure: (failure) {
                  emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
                },
              );
            },
            onFailure: (failure) {
              emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
            },
          );
        },
        onFailure: (failure) {
          emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
        },
      );
    } on Exception catch (e, stack) {
      _logger.e('Error loading dashboard', error: e, stackTrace: stack);
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }

  Future<void> _onWorkspaceSelected(
    WorkspaceSelected event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final selectedWorkspace = currentState.workspaces
        .where((w) => w.id == event.workspaceId)
        .firstOrNull;

    if (selectedWorkspace == null) return;

    emit(currentState.copyWith(
      selectedWorkspace: selectedWorkspace,
      conversations: [],
      selectedConversationIds: {},
      messages: [],
      users: {},
    ),);

    // Load conversations for new workspace
    final conversationsResult = await _conversationRepository.getConversations(
      selectedWorkspace.id,
    );

    conversationsResult.fold(
      onSuccess: (conversations) async {
        if (conversations.isEmpty) {
          emit(currentState.copyWith(
            selectedWorkspace: selectedWorkspace,
            conversations: [],
            selectedConversationIds: {},
            messages: [],
            users: {},
          ),);
          return;
        }

        final selectedConversation = conversations.first;
        _currentMessageStart = 0;

        // Load messages for first conversation
        final messagesResult = await _messageRepository.getRecentMessages(
          conversationId: selectedConversation.id,
        );

        messagesResult.fold(
          onSuccess: (messages) async {
            // Load users
            final userIds = messages.map((m) => m.userId).toSet().toList();
            final usersResult = await _userRepository.getUsers(userIds);

            // Create color map for conversations
            final colorMap = <String, int>{};
            for (final conversation in conversations) {
              if (conversation.colorIndex != null) {
                colorMap[conversation.id] = conversation.colorIndex!;
              }
            }

            usersResult.fold(
              onSuccess: (users) {
                final userMap = {for (final u in users) u.id: u};
                emit(currentState.copyWith(
                  selectedWorkspace: selectedWorkspace,
                  conversations: conversations,
                  selectedConversationIds: {selectedConversation.id},
                  messages: messages,
                  users: userMap,
                  conversationColorMap: colorMap,
                ),);
              },
              onFailure: (_) {
                emit(currentState.copyWith(
                  selectedWorkspace: selectedWorkspace,
                  conversations: conversations,
                  selectedConversationIds: {selectedConversation.id},
                  messages: messages,
                  users: {},
                  conversationColorMap: colorMap,
                ),);
              },
            );
          },
          onFailure: (failure) {
            emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
          },
        );
      },
      onFailure: (failure) {
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onConversationToggled(
    ConversationToggled event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final newSelectedIds = Set<String>.from(currentState.selectedConversationIds);
    if (newSelectedIds.contains(event.conversationId)) {
      newSelectedIds.remove(event.conversationId);
    } else {
      newSelectedIds.add(event.conversationId);
    }

    // If no conversations selected, clear messages
    if (newSelectedIds.isEmpty) {
      emit(currentState.copyWith(
        selectedConversationIds: {},
        messages: [],
        users: {},
      ),);
      return;
    }

    // Load messages from selected conversations
    await _loadMessagesFromSelectedConversations(emit, currentState, newSelectedIds);
  }

  Future<void> _onMultipleConversationsSelected(
    MultipleConversationsSelected event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    // Load messages from selected conversations
    await _loadMessagesFromSelectedConversations(emit, currentState, event.conversationIds);
  }

  Future<void> _onConversationSelectionCleared(
    ConversationSelectionCleared event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    emit(currentState.copyWith(
      selectedConversationIds: {},
      messages: [],
      users: {},
    ),);
  }

  Future<void> _loadMessagesFromSelectedConversations(
    Emitter<DashboardState> emit,
    DashboardLoaded currentState,
    Set<String> conversationIds,
  ) async {
    emit(currentState.copyWith(
      selectedConversationIds: conversationIds,
      messages: [],
      users: {},
    ),);

    // Load messages from multiple conversations
    final messagesResult = await _messageRepository.getMessagesFromConversations(
      conversationIds: conversationIds,
    );

    messagesResult.fold(
      onSuccess: (messages) async {
        // Load users for all messages
        final userIds = messages.map((m) => m.userId).toSet().toList();
        final usersResult = await _userRepository.getUsers(userIds);

        usersResult.fold(
          onSuccess: (users) {
            final userMap = {for (final u in users) u.id: u};
            emit(currentState.copyWith(
              selectedConversationIds: conversationIds,
              messages: messages,
              users: userMap,
            ),);
          },
          onFailure: (_) {
            emit(currentState.copyWith(
              selectedConversationIds: conversationIds,
              messages: messages,
              users: {},
            ),);
          },
        );
      },
      onFailure: (failure) {
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;
    if (currentState.selectedConversationIds.isEmpty) return;
    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;

    emit(currentState.copyWith(isLoadingMore: true));

    _currentMessageStart += _messagesPerPage;

    // For now, load more from the first selected conversation
    // TODO: Implement proper multi-conversation pagination
    final firstConversationId = currentState.selectedConversationIds.first;

    final messagesResult = await _messageRepository.getMessages(
      conversationId: firstConversationId,
      start: _currentMessageStart,
      count: _messagesPerPage,
    );

    messagesResult.fold(
      onSuccess: (newMessages) async {
        if (newMessages.isEmpty) {
          emit(currentState.copyWith(
            isLoadingMore: false,
            hasMoreMessages: false,
          ),);
          return;
        }

        // Merge with existing messages
        final allMessages = [...currentState.messages, ...newMessages];

        // Load new users
        final newUserIds = newMessages.map((m) => m.userId).toSet().toList();
        final usersResult = await _userRepository.getUsers(newUserIds);

        usersResult.fold(
          onSuccess: (newUsers) {
            final userMap = Map<String, User>.from(currentState.users);
            for (final user in newUsers) {
              userMap[user.id] = user;
            }

            emit(currentState.copyWith(
              messages: allMessages,
              users: userMap,
              isLoadingMore: false,
              hasMoreMessages: newMessages.length == _messagesPerPage,
            ),);
          },
          onFailure: (_) {
            emit(currentState.copyWith(
              messages: allMessages,
              isLoadingMore: false,
              hasMoreMessages: newMessages.length == _messagesPerPage,
            ),);
          },
        );
      },
      onFailure: (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onDashboardRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    // Clear all caches and reload
    _currentMessageStart = 0;
    add(const DashboardInitialized());
  }
}
