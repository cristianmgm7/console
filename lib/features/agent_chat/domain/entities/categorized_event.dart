import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_actions.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

/// Base class for categorized events emitted by the use cases.
///
/// This sealed class defines the different types of events that can be emitted
/// by domain use cases when processing raw ADK events. Each subclass represents
/// a specific type of event that presentation layer components can handle.
///
/// The categorization allows different UI components to subscribe to only the
/// events they care about, enabling clean separation of concerns.
sealed class CategorizedEvent extends Equatable {
  const CategorizedEvent(this.sourceEvent);

  final AdkEvent sourceEvent;

  @override
  List<Object?> get props => [sourceEvent];
}

/// A text message from the agent for display in the chat UI.
///
/// This event is emitted when the agent sends text content that should be
/// displayed to the user. The content may be partial (streaming) or complete.
///
/// ChatBloc listens for these events to update the conversation UI with
/// agent messages, handling both streaming text and final responses.
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

/// An authentication request from the agent that triggers an OAuth flow.
///
/// This event is emitted when the agent needs the user to authenticate with
/// an external service to enable MCP tools. McpAuthBloc listens for these
/// events and presents an authentication dialog to the user.
///
/// The event contains the complete [AuthenticationRequest] with OAuth2 parameters
/// needed to complete the authentication flow.
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
