import 'package:equatable/equatable.dart';

class MessageDetailState extends Equatable {
  const MessageDetailState({this.selectedMessageId});

  final String? selectedMessageId;

  bool get isVisible => selectedMessageId != null;

  MessageDetailState copyWith({String? selectedMessageId}) {
    return MessageDetailState(selectedMessageId: selectedMessageId);
  }

  @override
  List<Object?> get props => [selectedMessageId];
}
