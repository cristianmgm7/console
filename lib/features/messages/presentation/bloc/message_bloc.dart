import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc(
    this._messageRepository,
    this._userRepository,
    ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final int _messagesPerPage = 50;
  Set<String> _currentConversationIds = {};

  Future<void> _onConversationSelected(
    ConversationSelectedEvent event,
    Emitter<MessageState> emit,
  ) async {
    _currentConversationIds = event.conversationIds;
    if (event.conversationIds.isEmpty) {
      emit(const MessageLoaded(messages: [], users: {}));
      return;
    }
    add(LoadMessages(event.conversationIds));
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    emit(const MessageLoading());
    _currentConversationIds = event.conversationIds;

    final result = await _messageRepository.getMessagesFromConversations(
      conversationIds: event.conversationIds,
      count: _messagesPerPage,
    );

    result.fold(
      onSuccess: (messages) async => _loadUsersAndEmit(messages, emit),
      onFailure: (failure) => emit(MessageError(FailureMapper.mapToMessage(failure.failure))),
    );
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
          messages: messages,
          users: userMap,
          hasMoreMessages: messages.length == _messagesPerPage,
        ),);
      },
      onFailure: (_) => emit(MessageLoaded(
        messages: messages,
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

    result.fold(
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
            ),  );
          },
        );
      },
      onFailure: (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(MessageError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentConversationIds.isEmpty) return;

    add(LoadMessages(_currentConversationIds));
  }
}
