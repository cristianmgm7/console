import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
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
                        AuthRequestItem() => _buildAuthRequestCard(context, item),
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

  /// Build authentication request card
  Widget _buildAuthRequestCard(BuildContext context, AuthRequestItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: Colors.amber[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Authentication Required',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The agent needs authentication to continue.',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement authentication flow
                  // Could launch URL: launchUrl(Uri.parse(item.request.correctedAuthUri))
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Authenticate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
