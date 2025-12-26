import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/session_list_item.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/session_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';

class SessionListSidebar extends StatelessWidget {
  const SessionListSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          // Header with "New Chat" button
          Padding(
            padding: const EdgeInsets.all(16.0),
              child: AppButton(
              onPressed: () {
                context.read<SessionBloc>().add(const CreateNewSession());
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.add, size: 18),
                  const SizedBox(width: 8),
                  const Text('New Chat'),
                ],
              ),
            ),
          ),

          const Divider(),

          // Session list
          Expanded(
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, state) {
                if (state is SessionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SessionError) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  );
                }

                if (state is SessionLoaded) {
                  if (state.sessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No sessions yet.\nClick "New Chat" to start.',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      return SessionListItem(
                        sessionId: session.id,
                        title: 'Session ${session.id.substring(0, 8)}',
                        preview: session.lastMessagePreview ?? 'New conversation',
                        lastMessageTime: session.lastUpdateTime,
                        isSelected: session.id == state.selectedSessionId,
                        onTap: () {
                          context.read<SessionBloc>().add(SelectSession(session.id));
                          context.read<ChatBloc>().add(LoadMessages(session.id));
                        },
                        onDelete: () {
                          context.read<SessionBloc>().add(DeleteSession(session.id));
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
