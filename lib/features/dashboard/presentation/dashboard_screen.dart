import 'dart:async';

import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart' as conv_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/dashboard/models/audio_message.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/app_bar_dashboard.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/content_dashboard.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/table_header_dashboard.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupBlocCommunication() {
    // WorkspaceBloc -> ConversationBloc
    _workspaceSubscription = context.read<WorkspaceBloc>().stream.listen((state) {
      if (state is WorkspaceLoaded && state.selectedWorkspace != null) {
        context.read<ConversationBloc>().add(
          conv_events.WorkspaceSelectedEvent(state.selectedWorkspace!.id),
        );
      }
    });

    // ConversationBloc -> MessageBloc
    _conversationSubscription = context.read<ConversationBloc>().stream.listen((state) {
      if (state is ConversationLoaded) {
        context.read<MessageBloc>().add(
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

  void _toggleSelectAll(bool? value, int messageCount) {
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

  void _toggleMessageSelection(String messageId, bool? value) {
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
          Column(
            children: [
              // App Bar
              DashboardAppBar(
                onRefresh: _onRefresh,
                searchController: _searchController,
              ),

              // Table Header - only show when messages are loaded
              BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
                selector: (state) => state is MessageLoaded ? state : null,
                builder: (context, messageState) {
                  if (messageState == null || messageState.messages.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return DashboardTableHeader(
                    onToggleSelectAll: _toggleSelectAll,
                    messageState: messageState,
                    selectAll: _selectAll,
                  );
                },
              ),

              // Content
              Expanded(
                child: DashboardContent(
                  isAnyBlocLoading: _isAnyBlocLoading,
                  scrollController: _scrollController,
                  selectedMessages: _selectedMessages,
                  onToggleMessageSelection: _toggleMessageSelection,
                  convertToLegacyMessage: _convertToLegacyMessage,
                ),
              ),
            ],
          ),

          // Floating Action Panel
          if (_selectedMessages.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: MessagesActionPanel(
                  selectedCount: _selectedMessages.length,
                  onDownload: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
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

  // Temporary converter - should refactor MessageCard to use domain entities
  AudioMessage _convertToLegacyMessage(dynamic message, dynamic user) {
    // This is a hack to make the existing MessageCard work
    // In a real refactor, MessageCard should accept Message and User entities
    return AudioMessage(
      id: message.id as String,
      date: message.createdAt as DateTime,
      owner: user?.name as String? ?? 'Unknown User',
      message: message.text as String? ?? message.transcript as String? ?? 'No content',
      duration: message.duration as Duration? ?? Duration.zero,
      status: message.status as String? ?? 'Unknown',
      project: '', // Not available in Message entity
    );
  }
}
