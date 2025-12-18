import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageSelectionCubit extends Cubit<MessageSelectionState> {
  MessageSelectionCubit(this._logger) : super(const MessageSelectionState());

  final Logger _logger;

  /// Toggle selection for a single message
  void toggleMessage(String messageId, {bool? value}) {
    final newSelection = Set<String>.from(state.selectedMessageIds);

    if (value ?? !newSelection.contains(messageId)) {
      newSelection.add(messageId);
      _logger.d('Selected message: $messageId');
    } else {
      newSelection.remove(messageId);
      _logger.d('Deselected message: $messageId');
    }

    emit(
      state.copyWith(
        selectedMessageIds: newSelection,
        selectAll: false, // Clear select all when manually toggling
      ),
    );
  }

  /// Toggle select all
  void toggleSelectAll(List<String> allMessageIds, {bool? value}) {
    final shouldSelectAll = value ?? !state.selectAll;

    if (shouldSelectAll) {
      _logger.d('Selecting all ${allMessageIds.length} messages');
      emit(
        state.copyWith(
          selectedMessageIds: Set<String>.from(allMessageIds),
          selectAll: true,
        ),
      );
    } else {
      _logger.d('Clearing all selections');
      emit(const MessageSelectionState());
    }
  }

  /// Clear all selections
  void clearSelection() {
    _logger.d('Clearing selection');
    emit(const MessageSelectionState());
  }

  /// Get selected messages for operations
  Set<String> getSelectedMessageIds() {
    return Set<String>.from(state.selectedMessageIds);
  }
}
