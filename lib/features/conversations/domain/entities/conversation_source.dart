import 'package:equatable/equatable.dart';

/// Domain entity for source
class ConversationSource extends Equatable {
  const ConversationSource({
    this.type,
    this.value,
  });

  final String? type;
  final String? value;

  @override
  List<Object?> get props => [type, value];
}
