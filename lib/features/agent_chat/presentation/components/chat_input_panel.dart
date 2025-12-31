import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatInputPanel extends StatefulWidget {
  const ChatInputPanel({super.key});

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final sessionState = context.read<SessionBloc>().state;

    // If no sessions exist or none is selected, create a new session
    if (sessionState is! SessionLoaded ||
        sessionState.sessions.isEmpty ||
        sessionState.selectedSessionId == null) {
      // Create a new session and it will be auto-selected
      context.read<SessionBloc>().add(const CreateNewSession());
      // For now, return and let the user try again after the session is created
      return;
    }

    // Use the selected session
    final sessionId = sessionState.selectedSessionId!;

    // Load messages for this session if not already loaded
    final chatState = context.read<ChatBloc>().state;
    if (chatState is! ChatLoaded || chatState.currentSessionId != sessionId) {
      context.read<ChatBloc>().add(LoadMessages(sessionId));
    }

    // Send message - ChatBloc will detect auth requests and forward them automatically
    context.read<ChatBloc>().add(SendMessageStreaming(
      sessionId: sessionId,
      content: text,
    ));

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isSending = state is ChatLoaded && state.isSending;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isSending,
                  hint: isSending ? 'Sending...' : 'Ask the agent anything...',
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isSending ? null : (_) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 12),

              AppButton(
                onPressed: isSending ? null : _sendMessage,
                isLoading: isSending,
                child: Icon(AppIcons.share, size: 20), 
              ),
            ],
          ),
        );
      },
    );
  }
}
