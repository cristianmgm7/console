import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc(
    this._conversationRepository,
    this._logger,
  ) : super(const ConversationInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<ToggleConversation>(_onToggleConversation);
    on<SelectMultipleConversations>(_onSelectMultipleConversations);
    on<ClearConversationSelection>(_onClearConversationSelection);
    on<WorkspaceSelectedEvent>(_onWorkspaceSelected);
    on<OpenConversationSearch>(_onOpenConversationSearch);
    on<CloseConversationSearch>(_onCloseConversationSearch);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<ToggleSearchMode>(_onToggleSearchMode);
    on<SelectConversationFromSearch>(_onSelectConversationFromSearch);
  }

  final ConversationRepository _conversationRepository;
  final Logger _logger;

  /// Helper method to sort conversations by most recent activity
  List<Conversation> _sortConversationsByRecency(List<Conversation> conversations) {
    final sorted = List<Conversation>.from(conversations);

    sorted.sort((a, b) {
      final aTimestamp = a.lastPostedTs ?? a.lastUpdatedTs ?? a.createdTs ?? 0;
      final bTimestamp = b.lastPostedTs ?? b.lastUpdatedTs ?? b.createdTs ?? 0;

      return bTimestamp.compareTo(aTimestamp);
    });

    return sorted;
  }

  Future<void> _onWorkspaceSelected(
    WorkspaceSelectedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    add(LoadConversations(event.workspaceId));
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());

    final result = await _conversationRepository.getConversations(event.workspaceId);

    result.fold(
      onSuccess: (conversations) {
        if (conversations.isEmpty) {
          emit(const ConversationLoaded(
            conversations: [],
            selectedConversationIds: {},
            conversationColorMap: {},
          ),);
          return;
        }

        final sortedConversations = _sortConversationsByRecency(conversations);

        final colorMap = <String, int>{};
        for (var i = 0; i < sortedConversations.length; i++) {
          colorMap[sortedConversations[i].id] = i % 10;
        }

        final selected = sortedConversations.first;

        emit(ConversationLoaded(
          conversations: sortedConversations,
          selectedConversationIds: {selected.id},
          conversationColorMap: colorMap,
        ),);
        // State change will trigger dashboard screen to notify MessageBloc
      },
      onFailure: (failure) {
        emit(ConversationError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onToggleConversation(
    ToggleConversation event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot toggle conversation: current state is not ConversationLoaded');
      return;
    }

    final newSelectedIds = Set<String>.from(currentState.selectedConversationIds);
    final wasSelected = newSelectedIds.contains(event.conversationId);
    if (wasSelected) {
      newSelectedIds.remove(event.conversationId);
    } else {
      newSelectedIds.add(event.conversationId);
    }

    emit(currentState.copyWith(selectedConversationIds: newSelectedIds));
    // State change will trigger dashboard screen to notify MessageBloc
  }

  Future<void> _onSelectMultipleConversations(
    SelectMultipleConversations event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) return;

    emit(currentState.copyWith(selectedConversationIds: event.conversationIds));
    // State change will trigger dashboard screen to notify MessageBloc
  }

  Future<void> _onClearConversationSelection(
    ClearConversationSelection event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) return;

    emit(currentState.copyWith(selectedConversationIds: const <String>{}));
    // State change will trigger dashboard screen to notify MessageBloc
  }

  /// Handles opening the conversation search panel
  void _onOpenConversationSearch(
    OpenConversationSearch event,
    Emitter<ConversationState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot open search: current state is not ConversationLoaded');
      return;
    }

    emit(currentState.copyWith(
      isSearchOpen: true,
      searchQuery: '',
      searchMode: ConversationSearchMode.name,
    ));
  }

  /// Handles closing the conversation search panel
  void _onCloseConversationSearch(
    CloseConversationSearch event,
    Emitter<ConversationState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot close search: current state is not ConversationLoaded');
      return;
    }

    emit(currentState.copyWith(
      isSearchOpen: false,
      searchQuery: '',
    ));
  }

  /// Handles updating the search query
  void _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<ConversationState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot update search query: current state is not ConversationLoaded');
      return;
    }

    emit(currentState.copyWith(searchQuery: event.query));
  }

  /// Handles toggling between ID and Name search modes
  void _onToggleSearchMode(
    ToggleSearchMode event,
    Emitter<ConversationState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot toggle search mode: current state is not ConversationLoaded');
      return;
    }

    emit(currentState.copyWith(
      searchMode: event.searchMode,
      searchQuery: '',
    ));
  }

  /// Handles selecting a conversation from search results
  void _onSelectConversationFromSearch(
    SelectConversationFromSearch event,
    Emitter<ConversationState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot select from search: current state is not ConversationLoaded');
      return;
    }

    final newSelectedIds = Set<String>.from(currentState.selectedConversationIds);
    newSelectedIds.add(event.conversationId);

    emit(currentState.copyWith(
      selectedConversationIds: newSelectedIds,
      isSearchOpen: false,
      searchQuery: '',
    ));
    // State change will trigger dashboard screen to notify MessageBloc
  }
}
