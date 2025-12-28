import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_bloc.dart';
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
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is! SessionLoaded || sessionState.selectedSessionId == null) {
      return;
    }

    context.read<ChatBloc>().add(SendMessageStreaming(
      sessionId: sessionState.selectedSessionId!,
      content: text,
      context: null, // TODO: Add context support later
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
                child: Icon(AppIcons.share, size: 20), // TODO: Use paper plane icon if available
              ),
            ],
          ),
        );
      },
    );
  }
}
