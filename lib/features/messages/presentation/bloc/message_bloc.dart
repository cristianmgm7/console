import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation/mappers/message_ui_mapper.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart';

// Remove LoadMessageDetail import - now handled by MessageDetailBloc
// import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc(
    this._messageRepository,
    this._userRepository,
    this._logger,
  ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final Logger _logger;
  final int _messagesPerPage = 50;
  Set<String> _currentConversationIds = {};

  Future<void> _onConversationSelected(
    ConversationSelectedEvent event,
    Emitter<MessageState> emit,
  ) async {
    _logger.i('ConversationSelectedEvent received with conversationIds: ${event.conversationIds}');

    // If no conversations are selected, clear the messages immediately
    if (event.conversationIds.isEmpty) {
      _logger.i('No conversations selected, clearing messages');
      _currentConversationIds = {};
      emit(const MessageLoaded(messages: [], users: {}));
      return;
    }

    // Only load messages if the conversation selection has actually changed
    if (_currentConversationIds != event.conversationIds) {
      _logger.i('Conversation selection changed from $_currentConversationIds to ${event.conversationIds}, loading messages');
      _currentConversationIds = event.conversationIds;
      add(LoadMessages(event.conversationIds));
    } else {
      _logger.d('Conversation selection unchanged, skipping message reload');
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    _logger.d('Loading messages for conversations: ${event.conversationIds}');
    emit(const MessageLoading());
    _currentConversationIds = event.conversationIds;

    final result = await _messageRepository.getMessagesFromConversations(
      conversationIds: event.conversationIds,
      count: _messagesPerPage,
    );

    if (result.isSuccess) {
      final messages = result.valueOrNull!;
      _logger.i('Successfully loaded ${messages.length} messages from ${event.conversationIds.length} conversations');
      await _loadUsersAndEmit(messages, emit);
    } else {
      _logger.e('Failed to load messages: ${result.failureOrNull}');
      emit(MessageError(FailureMapper.mapToMessage(result.failureOrNull!)));
    }
  }

  Future<void> _loadUsersAndEmit(
    List<Message> messages,
    Emitter<MessageState> emit,
  ) async {
    final userIds = messages.map((m) => m.userId).toSet().toList();
    final userResult = await _userRepository.getUsers(userIds);

    userResult.fold(
      onSuccess: (users) {
        final userMap = {for (final u in users) u.id: u};
        emit(MessageLoaded(
          messages: messages.map((message) => message.toUiModel()).toList(),
          users: userMap,
          hasMoreMessages: messages.length == _messagesPerPage,
        ),);
      },
      onFailure: (_) => emit(MessageLoaded(
        messages: messages.map((message) => message.toUiModel()).toList(),
        users: const {},
        hasMoreMessages: messages.length == _messagesPerPage,
      ),),
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessageLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;
    if (_currentConversationIds.isEmpty) return;

    emit(currentState.copyWith(isLoadingMore: true));


    // For pagination with multiple conversations, we load more from all selected conversations
    final result = await _messageRepository.getMessagesFromConversations(
      conversationIds: _currentConversationIds,
      count: _messagesPerPage,
    );

    if (result.isSuccess) {
      final newMessages = result.valueOrNull!;
      if (newMessages.isEmpty) {
        emit(currentState.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ),);
        return;
      }

      // Merge with existing messages (convert new messages to UI models)
      final newUiMessages = newMessages.map((message) => message.toUiModel()).toList();
      final allMessages = [...currentState.messages, ...newUiMessages];

      // Load new users
      final newUserIds = newMessages.map((m) => m.userId).toSet().toList();
      final usersResult = await _userRepository.getUsers(newUserIds);

      if (usersResult.isSuccess) {
        final newUsers = usersResult.valueOrNull!;
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
      } else {
        emit(currentState.copyWith(
          messages: allMessages,
          isLoadingMore: false,
          hasMoreMessages: newMessages.length == _messagesPerPage,
        ),);
      }
    } else {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(MessageError(FailureMapper.mapToMessage(result.failureOrNull!)));
    }
  }

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentConversationIds.isEmpty) return;

    add(LoadMessages(_currentConversationIds));
  }

}
