import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart';
// Remove LoadMessageDetail import - now handled by MessageDetailBloc
// import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/mappers/message_ui_mapper.dart';
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

  // Track oldest timestamp per conversation for pagination
  final Map<String, DateTime> _conversationCursors = {};

  /// Cache for user profiles to avoid repeated API calls
  final Map<String, User> _profileCache = {};

  /// Gets cached user profiles, fetching missing ones from the repository
  Future<Map<String, User>> _getUsersWithCache(Set<String> userIds) async {
    final cachedUsers = <String, User>{};
    final missingUserIds = <String>[];

    // Check cache for existing users
    for (final userId in userIds) {
      final cachedUser = _profileCache[userId];
      if (cachedUser != null) {
        cachedUsers[userId] = cachedUser;
      } else {
        missingUserIds.add(userId);
      }
    }

    // Fetch missing users
    if (missingUserIds.isNotEmpty) {
      final result = await _userRepository.getUsers(missingUserIds);
      if (result.isSuccess) {
        final fetchedUsers = result.valueOrNull!;
        for (final user in fetchedUsers) {
          cachedUsers[user.id] = user;
          _profileCache[user.id] = user; // Update cache
        }
      } else {
        _logger.w('Failed to fetch users: ${result.failureOrNull}');
        // Return only cached users if fetch fails
      }
    }

    return cachedUsers;
  }

  Future<void> _onConversationSelected(
    ConversationSelectedEvent event,
    Emitter<MessageState> emit,
  ) async {
    // If no conversations are selected, clear everything
    if (event.conversationIds.isEmpty) {
      _currentConversationIds = {};
      _conversationCursors.clear(); // Clear cursors
      emit(const MessageLoaded(messages: []));
      return;
    }

    // Only load messages if the conversation selection has actually changed
    if (_currentConversationIds != event.conversationIds) {
      _currentConversationIds = event.conversationIds;
      _conversationCursors.clear(); // Clear cursors on conversation change
      add(LoadMessages(event.conversationIds));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    emit(const MessageLoading());
    _currentConversationIds = event.conversationIds;
    _conversationCursors.clear(); // Reset cursors on new load

    if (event.conversationIds.isEmpty) {
      emit(const MessageLoaded(messages: []));
      return;
    }

    try {
      final allMessages = <Message>[];

      // Fetch from each conversation using recent endpoint
      for (final conversationId in event.conversationIds) {
        final result = await _messageRepository.getRecentMessages(
          conversationId: conversationId,
          count: _messagesPerPage,
        );

        if (result.isSuccess) {
          final messages = result.valueOrNull!;
          allMessages.addAll(messages);

          // Track oldest timestamp for this conversation
          if (messages.isNotEmpty) {
            final oldestInConversation = messages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        } else {
          _logger.w('Failed to fetch messages from $conversationId: ${result.failureOrNull}');
          // Continue with other conversations
        }
      }

      // Sort all messages by date (newest first)
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate overall oldest timestamp
      final oldestTimestamp = allMessages.isNotEmpty
          ? allMessages.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
          : null;

      await _loadUsersAndEmit(
        allMessages,
        emit,
        oldestTimestamp: oldestTimestamp,
      );
    } on Exception catch (e, stack) {
      _logger.e('Error loading messages from multiple conversations', error: e, stackTrace: stack);
      emit(MessageError('Failed to load messages: $e'));
    }
  }

  Future<void> _loadUsersAndEmit(
    List<Message> messages,
    Emitter<MessageState> emit, {
    DateTime? oldestTimestamp,
  }) async {
    final userIds = messages.map((m) => m.userId).toSet();
    final userMap = await _getUsersWithCache(userIds);

    final enrichedMessages = messages.map((message) {
      final creator = userMap[message.creatorId];
      return message.toUiModel(creator);
    }).toList();

    emit(MessageLoaded(
      messages: enrichedMessages,
      hasMoreMessages: messages.length == _messagesPerPage,
      oldestMessageTimestamp: oldestTimestamp,
    ),);
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

    try {
      final newMessages = <Message>[];

      // Fetch next page from each conversation using its cursor
      for (final conversationId in _currentConversationIds) {
        final beforeTimestamp = _conversationCursors[conversationId];

        final result = await _messageRepository.getRecentMessages(
          conversationId: conversationId,
          count: _messagesPerPage,
          beforeTimestamp: beforeTimestamp,
        );

        if (result.isSuccess) {
          final messages = result.valueOrNull!;
          newMessages.addAll(messages);

          // Update cursor for this conversation
          if (messages.isNotEmpty) {
            final oldestInConversation = messages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        } else {
          _logger.w('Failed to fetch more messages from $conversationId: ${result.failureOrNull}');
        }
      }

      if (newMessages.isEmpty) {
        emit(currentState.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }

      // Sort new messages by date (newest first)
      newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate new overall oldest timestamp
      final newOldestTimestamp = newMessages.isNotEmpty
          ? newMessages.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
          : currentState.oldestMessageTimestamp;

      // Load users and enrich messages
      final newUserIds = newMessages.map((m) => m.userId).toSet();
      final newUserMap = await _getUsersWithCache(newUserIds);

      final newEnrichedMessages = newMessages.map((message) {
        final creator = newUserMap[message.creatorId];
        return message.toUiModel(creator);
      }).toList();

      // Append to existing messages
      final allMessages = [...currentState.messages, ...newEnrichedMessages];

      emit(currentState.copyWith(
        messages: allMessages,
        isLoadingMore: false,
        hasMoreMessages: newMessages.length >= _messagesPerPage,
        oldestMessageTimestamp: newOldestTimestamp,
      ));
    } on Exception catch (e, stack) {
      _logger.e('Error loading more messages', error: e, stackTrace: stack);
      emit(currentState.copyWith(isLoadingMore: false));
      emit(MessageError('Failed to load more messages: $e')); 
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
