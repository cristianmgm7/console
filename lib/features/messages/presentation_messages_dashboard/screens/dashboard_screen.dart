import 'dart:async';

import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart' as conv_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/widgets/circular_download_progress_widget.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart' as msg_events;
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/content_dashboard.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/components/message_detail_panel.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart' as ws_events;
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;

  // Message detail panel state
  String? _selectedMessageForDetail;

  // Message composition panel state
  bool _showMessageComposition = false;
  String? _compositionWorkspaceId;
  String? _compositionChannelId;
  String? _compositionReplyToMessageId;

  @override
  void initState() {
    super.initState();
    _setupBlocCommunication();
  }

  @override
  void dispose() {
    _workspaceSubscription.cancel();
    _conversationSubscription.cancel();
    super.dispose();
  }

  void _setupBlocCommunication() {
    // Store bloc references to avoid using context in async callbacks
    final workspaceBloc = context.read<WorkspaceBloc>();
    final conversationBloc = context.read<ConversationBloc>();
    final messageBloc = context.read<MessageBloc>();

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
  }

  Widget _buildErrorListeners() {
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
      child: const SizedBox.shrink(),
    );
  }


  void _toggleSelectAll(int messageCount, {bool? value}) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        final state = context.read<MessageBloc>().state;
        if (state is MessageLoaded) {
          _selectedMessages.addAll(state.messages.map((m) => m.id));
        }
      } else {
        _selectedMessages.clear();
      }
    });
  }

  void _toggleMessageSelection(String messageId, {bool? value}) {
    setState(() {
      if (value ?? false) {
        _selectedMessages.add(messageId);
      } else {
        _selectedMessages.remove(messageId);
      }
    });
  }

  void _onRefresh() {
    // Refresh all blocs by reloading workspaces
    context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
    setState(() {
      _selectedMessages.clear();
      _selectAll = false;
    });
  }

  void _onManualLoadMore() {
    context.read<MessageBloc>().add(const msg_events.LoadMoreMessages());
  }

  void _onDownloadAudio() {
    // Check for empty selection
    if (_selectedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create a copy of selected messages for the download
    final messagesToDownload = Set<String>.from(_selectedMessages);

    // Clear selection after capturing the messages to download
    setState(() {
      _selectedMessages.clear();
      _selectAll = false;
    });

    // Start download (no modal shown - progress indicator appears automatically)
    context.read<DownloadBloc>().add(StartDownloadAudio(messagesToDownload));
  }

  void _onDownloadTranscript() {
    // Check for empty selection
    if (_selectedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create a copy of selected messages for the download
    final messagesToDownload = Set<String>.from(_selectedMessages);

    // Clear selection after capturing the messages to download
    setState(() {
      _selectedMessages.clear();
      _selectAll = false;
    });

    // Start download (no modal shown - progress indicator appears automatically)
    context.read<DownloadBloc>().add(StartDownloadTranscripts(messagesToDownload));
  }

  void _onDownloadMessage(String messageId) {
    // Start download for single message
    context.read<DownloadBloc>().add(StartDownloadAudio({messageId}));
  }

  void _onSummarize() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Summarizing ${_selectedMessages.length} messages...'),
      ),
    );
  }

  void _onAIChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening AI chat for ${_selectedMessages.length} messages...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, downloadState) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              if (_selectedMessageForDetail == null) _buildFullDashboard() else _buildDashboardWithDetail(),

              // Error listeners
              _buildErrorListeners(),

              // Right-side circular progress indicator
              const Positioned(
                top: 100,
                right: 24,
                child: CircularDownloadProgressWidget(),
              ),

            ],
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
          onRefresh: _onRefresh,
          onSendMessage: _onSendMessage,
        ),

        // Content
        Expanded(
          child: BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
            selector: (state) => state is MessageLoaded ? state : null,
            builder: (context, messageState) {
              return DashboardContent(
                isAnyBlocLoading: _isAnyBlocLoading,
                selectedMessages: _selectedMessages,
                onToggleMessageSelection: _toggleMessageSelection,
                onToggleSelectAll: _toggleSelectAll,
                selectAll: _selectAll,
                onManualLoadMore: _onManualLoadMore,
                onViewDetail: _onViewDetail,
                onReply: _onReply,
                onDownloadMessage: _onDownloadMessage,
                onDownloadAudio: _onDownloadAudio,
                onDownloadTranscript: _onDownloadTranscript,
                onSummarize: _onSummarize,
                onAIChat: _onAIChat,
                showMessageComposition: _showMessageComposition,
                compositionWorkspaceId: _compositionWorkspaceId,
                compositionChannelId: _compositionChannelId,
                compositionReplyToMessageId: _compositionReplyToMessageId,
                onCloseMessageComposition: _onCloseMessageComposition,
                onMessageCompositionSuccess: _onMessageCompositionSuccess,
                onCancelReply: _onCancelReply,
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
            onRefresh: _onRefresh,
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
                    selectedMessages: _selectedMessages,
                    onToggleMessageSelection: _toggleMessageSelection,
                    onToggleSelectAll: _toggleSelectAll,
                    selectAll: _selectAll,
                    onManualLoadMore: _onManualLoadMore,
                    onViewDetail: _onViewDetail,
                    onReply: _onReply,
                    onDownloadMessage: _onDownloadMessage,
                    onDownloadAudio: _onDownloadAudio,
                    onDownloadTranscript: _onDownloadTranscript,
                    onSummarize: _onSummarize,
                    onAIChat: _onAIChat,
                    showMessageComposition: _showMessageComposition,
                    compositionWorkspaceId: _compositionWorkspaceId,
                    compositionChannelId: _compositionChannelId,
                    compositionReplyToMessageId: _compositionReplyToMessageId,
                  onCloseMessageComposition: _onCloseMessageComposition,
                  onMessageCompositionSuccess: _onMessageCompositionSuccess,
                  onCancelReply: _onCancelReply,
                );
                },
              ),
            ),
        
            // Right side: Detail panel
            if (_selectedMessageForDetail != null)
              MessageDetailPanel(
                messageId: _selectedMessageForDetail!,
                onClose: _onCloseDetail,
              ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  void _onViewDetail(String messageId) {
    setState(() {
      _selectedMessageForDetail = messageId;
    });
    // Load message details using the centralized bloc
    context.read<MessageDetailBloc>().add(LoadMessageDetail(messageId));
  }

  void _onCloseDetail() {
    setState(() {
      _selectedMessageForDetail = null;
    });
  }

  void _onReply(String messageId, String channelId) {
    final workspaceState = context.read<WorkspaceBloc>().state;
    final workspaceId = workspaceState is WorkspaceLoaded && workspaceState.selectedWorkspace != null
        ? workspaceState.selectedWorkspace!.id
        : '';

    if (workspaceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workspace selected')),
      );
      return;
    }

    setState(() {
      _showMessageComposition = true;
      _compositionWorkspaceId = workspaceId;
      _compositionChannelId = channelId;
      _compositionReplyToMessageId = messageId;
    });
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

    setState(() {
      _showMessageComposition = true;
      _compositionWorkspaceId = workspaceId;
      _compositionChannelId = channelId;
      _compositionReplyToMessageId = null; // null for new message, not reply
    });
  }

  void _onCloseMessageComposition() {
    setState(() {
      _showMessageComposition = false;
      _compositionWorkspaceId = null;
      _compositionChannelId = null;
      _compositionReplyToMessageId = null;
    });
  }

  void _onMessageCompositionSuccess() {
    // Refresh messages after successful message send
    context.read<MessageBloc>().add(const msg_events.RefreshMessages());
    _onCloseMessageComposition();
  }

  void _onCancelReply() {
    setState(() {
      _compositionReplyToMessageId = null;
    });
  }

}
