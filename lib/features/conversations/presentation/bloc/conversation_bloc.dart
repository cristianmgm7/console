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
          ));
          return;
        }

        final selected = conversations.first;
        _logger.i('Auto-selected conversation: ${selected.name}');

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
        ));

        add(ConversationSelectedEvent({selected.id}));
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
    if (currentState is! ConversationLoaded) return;

    final newSelectedIds = Set<String>.from(currentState.selectedConversationIds);
    if (newSelectedIds.contains(event.conversationId)) {
      newSelectedIds.remove(event.conversationId);
    } else {
      newSelectedIds.add(event.conversationId);
    }

    emit(currentState.copyWith(selectedConversationIds: newSelectedIds));
    add(ConversationSelectedEvent(newSelectedIds));
  }

  Future<void> _onSelectMultipleConversations(
    SelectMultipleConversations event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) return;

    emit(currentState.copyWith(selectedConversationIds: event.conversationIds));
    add(ConversationSelectedEvent(event.conversationIds));
  }

  Future<void> _onClearConversationSelection(
    ClearConversationSelection event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) return;

    emit(currentState.copyWith(selectedConversationIds: const <String>{}));
    add(ConversationSelectedEvent({}));
  }
}
