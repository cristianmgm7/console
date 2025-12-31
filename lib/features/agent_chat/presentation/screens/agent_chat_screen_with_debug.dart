import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/chat_conversation_area.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/components/session_list_sidebar.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/stream_debug_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Agent Chat Screen with Debug Overlay for testing SSE streaming.
///
/// This version includes the StreamDebugOverlay to visualize events
/// as they arrive from the SSE stream in real-time.
///
/// To use this version instead of the regular one:
/// 1. Import this file in your router
/// 2. Replace AgentChatScreen with AgentChatScreenWithDebug
///
/// Or simply copy the changes to your existing agent_chat_screen.dart
class AgentChatScreenWithDebug extends StatefulWidget {
  const AgentChatScreenWithDebug({super.key});

  @override
  State<AgentChatScreenWithDebug> createState() => _AgentChatScreenWithDebugState();
}

class _AgentChatScreenWithDebugState extends State<AgentChatScreenWithDebug> {
  @override
  void initState() {
    super.initState();
    
    // Hook up debug event callback after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatBloc = context.read<ChatBloc>();
      
      // Set up debug event logging
      chatBloc.onDebugEvent = (event) {
        if (mounted) {
          StreamDebugOverlay.logEvent(context, event);
        }
      };
      
      debugPrint('✅ Debug overlay connected to ChatBloc');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const StreamDebugOverlay(
      enabled: kDebugMode, // Only in debug builds
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Session list sidebar (250px)
            SessionListSidebar(),

            // Divider
            VerticalDivider(
              width: 1,
              color: AppColors.border,
            ),

            // Main chat area
            Expanded(
              child: ChatConversationArea(),
            ),
          ],
        ),
      ),
    );
  }
}

