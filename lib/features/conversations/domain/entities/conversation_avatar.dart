import 'package:equatable/equatable.dart';

/// Domain entity for individual avatar
class ConversationAvatar extends Equatable {
  const ConversationAvatar({
    this.children,
    this.type,
    this.imageUrl,
    this.text,
  });

  final List<ConversationAvatar>? children;
  final String? type;
  final String? imageUrl;
  final String? text;

  @override
  List<Object?> get props => [children, type, imageUrl, text];
}
