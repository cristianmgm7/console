import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/auth_request_card.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/chat_input_panel.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/tool_confirmation_card.dart';
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
                  if (state.items.isEmpty) {
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
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];

                      // Pattern matching on ChatItem type
                      return switch (item) {
                        TextMessageItem() => ChatMessageBubble(
                            content: item.text,
                            role: item.role,
                            timestamp: item.timestamp,
                            subAgentName: item.subAgentName,
                            subAgentIcon: item.subAgentIcon,
                          ),
                        SystemStatusItem() => AgentStatusIndicator(
                            message: item.status,
                            subAgentName: item.subAgentName,
                          ),
                        AuthRequestItem() => AuthRequestCard(
                            item: item,
                            sessionId: state.currentSessionId,
                          ),
                        ToolConfirmationItem() => ToolConfirmationCard(
                            item: item,
                          ),
                      };
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
