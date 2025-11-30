import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
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
  }

  final ConversationRepository _conversationRepository;
  final Logger _logger;

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

        final selected = conversations.first;

        final colorMap = <String, int>{};
        for (final conversation in conversations) {
          if (conversation.colorIndex != null) {
            colorMap[conversation.id] = conversation.colorIndex!;
          }
        }

        emit(ConversationLoaded(
          conversations: conversations,
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
}
