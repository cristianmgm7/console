import 'package:equatable/equatable.dart';

class AgentChatSession extends Equatable {

  const AgentChatSession({
    required this.id,
    required this.userId,
    required this.appName,
    required this.createdAt,
    required this.lastUpdateTime,
    this.state = const {},
    this.lastMessagePreview,
  });
  final String id;
  final String userId;
  final String appName;
  final DateTime createdAt;
  final DateTime lastUpdateTime;
  final Map<String, dynamic> state;
  final String? lastMessagePreview;

  @override
  List<Object?> get props => [
        id,
        userId,
        appName,
        createdAt,
        lastUpdateTime,
        state,
        lastMessagePreview,
      ];

  AgentChatSession copyWith({
    String? id,
    String? userId,
    String? appName,
    DateTime? createdAt,
    DateTime? lastUpdateTime,
    Map<String, dynamic>? state,
    String? lastMessagePreview,
  }) {
    return AgentChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appName: appName ?? this.appName,
      createdAt: createdAt ?? this.createdAt,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      state: state ?? this.state,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
