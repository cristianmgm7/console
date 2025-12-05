import 'package:equatable/equatable.dart';

class MessageSelectionState extends Equatable {
  const MessageSelectionState({
    this.selectedMessageIds = const {},
    this.selectAll = false,
  });

  final Set<String> selectedMessageIds;
  final bool selectAll;

  int get selectedCount => selectedMessageIds.length;
  bool get hasSelection => selectedMessageIds.isNotEmpty;

  MessageSelectionState copyWith({
    Set<String>? selectedMessageIds,
    bool? selectAll,
  }) {
    return MessageSelectionState(
      selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
      selectAll: selectAll ?? this.selectAll,
    );
  }

  @override
  List<Object?> get props => [selectedMessageIds, selectAll];
}
