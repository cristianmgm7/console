import 'dart:async';

import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart' as conv_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/app_bar_dashboard.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/content_dashboard.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/dashboard_panels.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart' as msg_events;
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
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
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;

  // Message detail panel state
  String? _selectedMessageForDetail;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _setupBlocCommunication();
  }

  @override
  Future<void> dispose() async {
    await _workspaceSubscription.cancel();
    await _conversationSubscription.cancel();
    _scrollController.dispose();
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // Near bottom, load more
      context.read<MessageBloc>().add(const msg_events.LoadMoreMessages());
    }
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          _buildDashboardWithPanels(),

          // Floating Action Panel - only show when no detail is selected
          if (_selectedMessages.isNotEmpty && _selectedMessageForDetail == null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: MessagesActionPanel(
                  selectedCount: _selectedMessages.length,
                  onDownloadAudio: _handleDownloadAudio,
                  onDownloadTranscript: _handleDownloadTranscript,
                  onSummarize: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Summarizing ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onAIChat: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening AI chat for ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Error listeners
          _buildErrorListeners(),
        ],
      ),
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

  Widget _buildDashboardWithPanels() {
    return SizedBox.expand(
      child: Column(
        children: [
          // App Bar - full width at top
          DashboardAppBar(
            onRefresh: _onRefresh,
          ),

          // Main content area with panels
          Expanded(
            child: Stack(
              children: [
                // Left side: Message list area (full width)
                BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
                  selector: (state) => state is MessageLoaded ? state : null,
                  builder: (context, messageState) {
                    return DashboardContent(
                      isAnyBlocLoading: _isAnyBlocLoading,
                      scrollController: _scrollController,
                      selectedMessages: _selectedMessages,
                      onToggleMessageSelection: _toggleMessageSelection,
                      onToggleSelectAll: _toggleSelectAll,
                      selectAll: _selectAll,
                      onViewDetail: _onViewDetail,
                    );
                  },
                ),

                // Right side: All panels (orchestrated)
                DashboardPanels(
                  selectedMessageForDetail: _selectedMessageForDetail,
                  onCloseDetail: _onCloseDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDownloadAudio() {
    if (_selectedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final messagesToDownload = Set<String>.from(_selectedMessages);

    setState(() {
      _selectedMessages.clear();
      _selectAll = false;
    });

    // Trigger download via existing BLoC (no bottom sheet)
    context.read<DownloadBloc>().add(StartDownloadAudio(messagesToDownload));
  }

  void _handleDownloadTranscript() {
    if (_selectedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final messagesToDownload = Set<String>.from(_selectedMessages);

    setState(() {
      _selectedMessages.clear();
      _selectAll = false;
    });

    // Trigger download via existing BLoC (no bottom sheet)
    context.read<DownloadBloc>().add(StartDownloadTranscripts(messagesToDownload));
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

}
