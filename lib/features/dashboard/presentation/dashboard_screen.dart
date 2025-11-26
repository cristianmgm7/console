import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/dashboard/models/audio_message.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/message_card.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(const DashboardInitialized()),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatefulWidget {
  const _DashboardScreenContent();

  @override
  State<_DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<_DashboardScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // Near bottom, load more
      context.read<DashboardBloc>().add(const LoadMoreMessages());
    }
  }

  void _toggleSelectAll(bool? value, int messageCount) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        final state = context.read<DashboardBloc>().state;
        if (state is DashboardLoaded) {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              Column(
                children: [
                  // App Bar
                  _buildAppBar(context, state),

                  // Table Header
                  if (state is DashboardLoaded && state.messages.isNotEmpty)
                    _buildTableHeader(context, state),

                  // Content
                  Expanded(
                    child: _buildContent(context, state),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, DashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Audio Messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(width: 32),

          // Workspace Dropdown
          if (state is DashboardLoaded && state.workspaces.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: state.selectedWorkspace?.id,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.arrow_drop_down),
                items: state.workspaces.map((workspace) {
                  return DropdownMenuItem<String>(
                    value: workspace.id,
                    child: Text(workspace.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    context.read<DashboardBloc>().add(WorkspaceSelected(newValue));
                    setState(() {
                      _selectedMessages.clear();
                      _selectAll = false;
                    });
                  }
                },
              ),
            ),

          const SizedBox(width: 16),

          // Search Field (Conversation ID search - not implemented yet)
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Conversation ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Conversation Name Display
          if (state is DashboardLoaded && state.selectedConversationIds.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      state.conversations
                          .where((c) => state.selectedConversationIds.contains(c.id))
                          .map((c) => c.name)
                          .join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Refresh button
          if (state is DashboardLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<DashboardBloc>().add(const DashboardRefreshed());
                setState(() {
                  _selectedMessages.clear();
                  _selectAll = false;
                });
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            // Select All Checkbox
            Checkbox(
              value: _selectAll,
              onChanged: (value) => _toggleSelectAll(value, state.messages.length),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(width: 8),

            // Headers
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(Icons.arrow_upward, size: 16),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 140,
              child: Text(
                'Owner',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                'Message',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 16),
            const SizedBox(width: 60), // AI Action space
            const SizedBox(width: 16),

            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    'Dur',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(Icons.unfold_more, size: 16),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 90,
              child: Text(
                'Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 56), // Menu space
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<DashboardBloc>().add(const DashboardInitialized()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      if (state.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'No messages',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('No messages found in this conversation'),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messages.length) {
              // Loading more indicator
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final message = state.messages[index];
            final user = state.users[message.userId];

            // Convert domain entities to legacy AudioMessage format for MessageCard
            // TODO: Refactor MessageCard to accept domain entities directly
            final legacyMessage = _convertToLegacyMessage(message, user);

            return MessageCard(
              message: legacyMessage,
              isSelected: _selectedMessages.contains(message.id),
              onSelected: (value) => _toggleMessageSelection(message.id, value),
            );
          },
        ),
      );
    }

    return const Center(child: Text('Unknown state'));
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

