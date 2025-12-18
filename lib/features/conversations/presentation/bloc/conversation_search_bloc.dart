import 'package:carbon_voice_console/core/errors/failure_mapper.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class ConversationSearchBloc extends Bloc<ConversationSearchEvent, ConversationSearchState> {
  ConversationSearchBloc(
    this._conversationRepository,
    this._logger,
  ) : super(const ConversationSearchClosed()) {
    on<OpenConversationSearch>(_onOpenSearch);
    on<CloseConversationSearch>(_onCloseSearch);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<ToggleSearchMode>(_onToggleSearchMode);
    on<SearchConversationById>(_onSearchConversationById);
  }

  final ConversationRepository _conversationRepository;
  final Logger _logger;

  /// Currently loaded conversations for name-based filtering
  List<Conversation> _loadedConversations = [];

  /// Update the list of loaded conversations for name-based search
  void updateLoadedConversations(List<Conversation> conversations) {
    _loadedConversations = conversations;
  }

  /// Opens the search panel
  void _onOpenSearch(
    OpenConversationSearch event,
    Emitter<ConversationSearchState> emit,
  ) {
    emit(const ConversationSearchOpen());
  }

  /// Closes the search panel and resets state
  void _onCloseSearch(
    CloseConversationSearch event,
    Emitter<ConversationSearchState> emit,
  ) {
    emit(const ConversationSearchClosed());
  }

  /// Updates the search query and performs search based on mode
  Future<void> _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<ConversationSearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationSearchOpen) {
      _logger.w('Cannot update search query: search panel is not open');
      return;
    }

    final query = event.query.trim();

    // If query is empty, reset to open state
    if (query.isEmpty) {
      emit(currentState.copyWith(
        searchQuery: '',
        filteredConversations: [],
        isSearching: false,
      ));
      return;
    }

    // Update query and perform search based on mode
    if (currentState.searchMode == ConversationSearchMode.id) {
      // For ID search, trigger API call
      emit(currentState.copyWith(
        searchQuery: query,
        isSearching: true,
      ));

      add(SearchConversationById(query));
    } else {
      // For name search, filter loaded conversations client-side
      final filtered = _loadedConversations
          .where((c) =>
              (c.channelName ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();

      emit(currentState.copyWith(
        searchQuery: query,
        filteredConversations: filtered,
        isSearching: false,
      ));
    }
  }

  /// Toggles between ID and Name search modes
  void _onToggleSearchMode(
    ToggleSearchMode event,
    Emitter<ConversationSearchState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationSearchOpen) {
      _logger.w('Cannot toggle search mode: search panel is not open');
      return;
    }

    emit(currentState.copyWith(
      searchMode: event.searchMode,
      searchQuery: '',
      filteredConversations: [],
      isSearching: false,
    ));
  }

  /// Searches for a conversation by ID using the API
  Future<void> _onSearchConversationById(
    SearchConversationById event,
    Emitter<ConversationSearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationSearchOpen) {
      _logger.w('Cannot search by ID: search panel is not open');
      return;
    }

    emit(currentState.copyWith(isSearching: true));

    final result = await _conversationRepository.getConversation(event.conversationId);

    result.fold(
      onSuccess: (conversation) {
        emit(currentState.copyWith(
          filteredConversations: [conversation],
          isSearching: false,
        ));
      },
      onFailure: (failure) {
        final errorMessage = FailureMapper.mapToMessage(failure.failure);
        _logger.e('Failed to search conversation by ID: $errorMessage');

        // Show empty results with the error
        emit(currentState.copyWith(
          filteredConversations: [],
          isSearching: false,
        ));
      },
    );
  }
}
