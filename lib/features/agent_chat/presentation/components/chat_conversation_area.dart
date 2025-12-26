import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/chat_message_bubble.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/chat_input_panel.dart';

class ChatConversationArea extends StatelessWidget {
  const ChatConversationArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message list
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 0, // TODO: Connect to BLoC state
              itemBuilder: (context, index) {
                // TODO: Implement ChatMessageBubble in Phase 2
                return const SizedBox.shrink();
              },
            ),
          ),
        ),

        // Input panel at bottom
        const ChatInputPanel(),
      ],
    );
  }
}
