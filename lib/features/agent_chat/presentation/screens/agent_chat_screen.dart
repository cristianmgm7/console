import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/session_list_sidebar.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/chat_conversation_area.dart';

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({super.key});

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Session list sidebar (250px)
          const SessionListSidebar(),

          // Divider
          VerticalDivider(
            width: 1,
            color: AppColors.border,
          ),

          // Main chat area
          const Expanded(
            child: ChatConversationArea(),
          ),
        ],
      ),
    );
  }
}
