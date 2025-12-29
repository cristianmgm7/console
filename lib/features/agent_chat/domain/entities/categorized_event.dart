import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

/// Base class for categorized events emitted by the coordinator
sealed class CategorizedEvent extends Equatable {
  const CategorizedEvent(this.sourceEvent);

  final AdkEvent sourceEvent;

  @override
  List<Object?> get props => [sourceEvent];
}

/// A text message from the agent (for chat UI)
class ChatMessageEvent extends CategorizedEvent {
  const ChatMessageEvent({
    required AdkEvent sourceEvent,
    required this.text,
    required this.isPartial,
  }) : super(sourceEvent);

  final String text;
  final bool isPartial;

  @override
  List<Object?> get props => [...super.props, text, isPartial];
}

/// A function call being executed by the agent (for status indicators)
class FunctionCallEvent extends CategorizedEvent {
  const FunctionCallEvent({
    required AdkEvent sourceEvent,
    required this.functionName,
    required this.args,
  }) : super(sourceEvent);

  final String functionName;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [...super.props, functionName, args];
}

/// A function call result (mostly for logging/debugging)
class FunctionResponseEvent extends CategorizedEvent {
  const FunctionResponseEvent({
    required AdkEvent sourceEvent,
    required this.functionName,
    required this.response,
  }) : super(sourceEvent);

  final String functionName;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [...super.props, functionName, response];
}

/// An authentication request from the agent (triggers OAuth flow)
class AuthenticationRequestEvent extends CategorizedEvent {
  const AuthenticationRequestEvent({
    required AdkEvent sourceEvent,
    required this.request,
  }) : super(sourceEvent);

  final AuthenticationRequest request;

  @override
  List<Object?> get props => [...super.props, request];
}

/// An error occurred during agent execution
class AgentErrorEvent extends CategorizedEvent {
  const AgentErrorEvent({
    required AdkEvent sourceEvent,
    required this.errorMessage,
  }) : super(sourceEvent);

  final String errorMessage;

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
