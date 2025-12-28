import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/chat_input_panel.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/agent_status_indicator.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatConversationArea extends StatelessWidget {
  const ChatConversationArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message list
        Expanded(
          child: ColoredBox(
            color: AppColors.background,
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatError) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  );
                }

                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start a conversation',
                            style: AppTextStyle.headlineMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask the agent anything to get started',
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.messages.length + (state.statusMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show status indicator as last item
                      if (state.statusMessage != null && index == state.messages.length) {
                        return AgentStatusIndicator(
                          message: state.statusMessage!,
                          subAgentName: state.statusSubAgent,
                        );
                      }

                      final message = state.messages[index];
                      return ChatMessageBubble(
                        content: message.content,
                        role: message.role,
                        timestamp: message.timestamp,
                        subAgentName: message.subAgentName,
                        subAgentIcon: message.subAgentIcon,
                      );
                    },
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Select a session',
                        style: AppTextStyle.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a chat session from the sidebar to start messaging',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
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
