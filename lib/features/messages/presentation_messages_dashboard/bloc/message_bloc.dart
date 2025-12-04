import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/usecases/get_messages_from_conversations_usecase.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart';
// Remove LoadMessageDetail import - now handled by MessageDetailBloc
// import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc(
    this._userRepository,
    this._getMessagesFromConversationsUsecase,
    this._logger,
  ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  final UserRepository _userRepository;
  final GetMessagesFromConversationsUsecase _getMessagesFromConversationsUsecase;
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
      // Initialize cursors for new conversations (null = start from now)
      final cursors = {for (final id in event.conversationIds) id: null};

      final result = await _getMessagesFromConversationsUsecase(
        conversationCursors: cursors,
        count: _messagesPerPage,
      );

      if (result.isSuccess) {
        final resultData = result.valueOrNull!;
        final allMessages = resultData.messages;
        final hasMoreMessages = resultData.hasMoreMessages;

        // Update cursors for each conversation based on the oldest message received for that conversation
        for (final conversationId in event.conversationIds) {
          final conversationMessages = allMessages.where(
            (m) => m.channelIds.contains(conversationId),
          );
          if (conversationMessages.isNotEmpty) {
            final oldestInConversation = conversationMessages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        }

        // Calculate overall oldest timestamp
        final oldestTimestamp = allMessages.isNotEmpty
            ? allMessages.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
            : null;

        await _loadUsersAndEmit(
          allMessages,
          emit,
          oldestTimestamp: oldestTimestamp,
          hasMoreMessages: hasMoreMessages,
        );
      } else {
        _logger.e('Failed to load messages: ${result.failureOrNull}');
        emit(
          MessageError(
            'Failed to load messages: ${result.failureOrNull?.details ?? result.failureOrNull?.code}',
          ),
        );
      }
    } on Exception catch (e, stack) {
      _logger.e('Error loading messages from multiple conversations', error: e, stackTrace: stack);
      emit(MessageError('Failed to load messages: $e'));
    }
  }

  Future<void> _loadUsersAndEmit(
    List<Message> messages,
    Emitter<MessageState> emit, {
    DateTime? oldestTimestamp,
    bool? hasMoreMessages,
  }) async {
    final userIds = messages.map((m) => m.userId).toSet();
    final userMap = await _getUsersWithCache(userIds);

    final enrichedMessages = messages.map((message) {
      final creator = userMap[message.creatorId];
      return message.toUiModel(creator);
    }).toList();

    emit(
      MessageLoaded(
        messages: enrichedMessages,
        hasMoreMessages: hasMoreMessages ?? messages.length == _messagesPerPage,
        oldestMessageTimestamp: oldestTimestamp,
      ),
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

    try {
      // Use current cursors for pagination
      final result = await _getMessagesFromConversationsUsecase(
        conversationCursors: _conversationCursors,
        count: _messagesPerPage,
      );

      if (result.isSuccess) {
        final resultData = result.valueOrNull!;
        final newMessages = resultData.messages;
        final hasMoreMessages = resultData.hasMoreMessages;

        // Update cursors for each conversation
        for (final conversationId in _currentConversationIds) {
          final conversationMessages = newMessages.where(
            (m) => m.channelIds.contains(conversationId),
          );
          if (conversationMessages.isNotEmpty) {
            final oldestInConversation = conversationMessages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        }

        // If no new messages were fetched, we've reached the end
        if (newMessages.isEmpty) {
          emit(
            currentState.copyWith(
              isLoadingMore: false,
              hasMoreMessages: false,
            ),
          );
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

        // Sort entire list by date (newest first) to maintain order across pagination batches
        allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(
          currentState.copyWith(
            messages: allMessages,
            isLoadingMore: false,
            hasMoreMessages: hasMoreMessages,
            oldestMessageTimestamp: newOldestTimestamp,
          ),
        );
      } else {
        _logger.w('Failed to load more messages: ${result.failureOrNull}');
        emit(currentState.copyWith(isLoadingMore: false));
      }
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
