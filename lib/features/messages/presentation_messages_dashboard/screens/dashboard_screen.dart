import 'dart:async';

import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart' as conv_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart' as msg_events;
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_detail_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_detail_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/screens/content_dashboard.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart'
    show LoadMessageDetail, MessageDetailBloc;
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/components/message_detail_panel.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;
  late final StreamSubscription<MessageDetailState> _messageDetailSubscription;

  @override
  void initState() {
    super.initState();
    _setupBlocCommunication();
  }

  @override
  Future<void> dispose() async {
    await _workspaceSubscription.cancel();
    await _conversationSubscription.cancel();
    await _messageDetailSubscription.cancel();
    super.dispose();
  }

  void _setupBlocCommunication() {
    // Store bloc references to avoid using context in async callbacks
    final workspaceBloc = context.read<WorkspaceBloc>();
    final conversationBloc = context.read<ConversationBloc>();
    final messageBloc = context.read<MessageBloc>();
    final messageDetailCubit = context.read<MessageDetailCubit>();
    final messageDetailBloc = context.read<MessageDetailBloc>();

    // WorkspaceBloc -> ConversationBloc
    _workspaceSubscription = workspaceBloc.stream.listen((state) {
      if (state is WorkspaceLoaded && state.selectedWorkspace != null) {
        conversationBloc.add(
          conv_events.WorkspaceSelectedEvent(state.selectedWorkspace!.id),
        );
      }
    });

    // ConversationBloc -> MessageBloc
    _conversationSubscription = conversationBloc.stream.listen((state) {
      if (state is ConversationLoaded) {
        messageBloc.add(
          msg_events.ConversationSelectedEvent(state.selectedConversationIds),
        );
      }
    });

    // MessageDetailCubit -> MessageDetailBloc
    _messageDetailSubscription = messageDetailCubit.stream.listen((state) {
      if (state.selectedMessageId != null) {
        messageDetailBloc.add(LoadMessageDetail(state.selectedMessageId!));
      }
    });
  }

  void _onManualLoadMore() {
    context.read<MessageBloc>().add(const msg_events.LoadMoreMessages());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, downloadState) {
        return MultiBlocListener(
          listeners: [
            BlocListener<WorkspaceBloc, WorkspaceState>(
              listener: (context, state) {
                if (state is WorkspaceError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
            BlocListener<ConversationBloc, ConversationState>(
              listener: (context, state) {
                if (state is ConversationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
            BlocListener<MessageBloc, MessageState>(
              listener: (context, state) {
                if (state is MessageError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<MessageDetailCubit, MessageDetailState>(
            builder: (context, detailState) {
              return ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: !detailState.isVisible ? _buildFullDashboard() : _buildDashboardWithDetail(),
              );
            },
          ),
        );
      },
    );
  }



  bool _isAnyBlocLoading(BuildContext context) {
    final workspaceState = context.watch<WorkspaceBloc>().state;
    final conversationState = context.watch<ConversationBloc>().state;
    final messageState = context.watch<MessageBloc>().state;

    return workspaceState is WorkspaceLoading ||
           conversationState is ConversationLoading ||
           messageState is MessageLoading;
  }

  Widget _buildFullDashboard() {
    return Column(
      children: [
        // App Bar
        DashboardAppBar(
          onSendMessage: _onSendMessage,
        ),

        // Content
        Expanded(
          child: BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
            selector: (state) => state is MessageLoaded ? state : null,
            builder: (context, messageState) {
              return DashboardContent(
                isAnyBlocLoading: _isAnyBlocLoading,
                onManualLoadMore: _onManualLoadMore,
                hasMoreMessages: messageState?.hasMoreMessages ?? false,
                isLoadingMore: messageState?.isLoadingMore ?? false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardWithDetail() {
    return SizedBox.expand(
      child: Column(
        children: [
          // App Bar - full width at top
          DashboardAppBar(
            onSendMessage: _onSendMessage,
          ),
          // Main content area below app bar: left = messages, right = detail
          Expanded(
            child: Row(
          children: [
            // Left side: Message list area
            Expanded(
              child: BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
                selector: (state) => state is MessageLoaded ? state : null,
                builder: (context, messageState) {
                  return DashboardContent(
                    isAnyBlocLoading: _isAnyBlocLoading,
                    onManualLoadMore: _onManualLoadMore,
                    hasMoreMessages: messageState?.hasMoreMessages ?? false,
                    isLoadingMore: messageState?.isLoadingMore ?? false,
                  );
                },
              ),
            ),
        
            // Right side: Detail panel
            BlocBuilder<MessageDetailCubit, MessageDetailState>(
              builder: (context, detailState) {
                if (!detailState.isVisible) return const SizedBox.shrink();

                return MessageDetailPanel(
                  messageId: detailState.selectedMessageId!,
                  onClose: () {
                    context.read<MessageDetailCubit>().closeDetail();
                  },
                );
              },
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  void _onSendMessage() {
    final workspaceState = context.read<WorkspaceBloc>().state;
    final conversationState = context.read<ConversationBloc>().state;

    final workspaceId = workspaceState is WorkspaceLoaded && workspaceState.selectedWorkspace != null
        ? workspaceState.selectedWorkspace!.id
        : '';

    if (workspaceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workspace selected')),
      );
      return;
    }

    if (conversationState is! ConversationLoaded || conversationState.selectedConversationIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exactly one conversation')),
      );
      return;
    }

    // Find the selected conversation to get the correct channel ID
    final selectedConversationId = conversationState.selectedConversationIds.first;
    final selectedConversation = conversationState.conversations
        .where((c) => c.id == selectedConversationId)
        .firstOrNull;

    if (selectedConversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected conversation not found')),
      );
      return;
    }

    // Use the conversation's channelGuid as the channelId
    final channelId = selectedConversation.channelGuid ?? selectedConversation.id;

    context.read<MessageCompositionCubit>().openNewMessage(
      workspaceId: workspaceId,
      channelId: channelId,
    );
  }


}
