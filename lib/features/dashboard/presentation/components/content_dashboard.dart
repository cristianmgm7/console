import 'package:carbon_voice_console/features/dashboard/presentation/components/message_card.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart' as ws_events;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.scrollController,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    super.key,
  });

  final ScrollController scrollController;
  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final bool Function(BuildContext context) isAnyBlocLoading;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, messageState) {
        // Show loading when any bloc is loading
        if (isAnyBlocLoading(context)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messageState is MessageError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(messageState.message),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Retry by reloading workspaces
                    context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        // empty state
        if (messageState is MessageLoaded) {
          if (messageState.messages.isEmpty) {
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
              controller: scrollController,
              itemCount: messageState.messages.length + (messageState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messageState.messages.length) {
                  // Loading more indicator
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final message = messageState.messages[index];
                final user = messageState.users[message.userId];

                return MessageCard(
                  message: message,
                  user: user,
                  isSelected: selectedMessages.contains(message.id),
                  onSelected: (value) => onToggleMessageSelection(message.id, value: value),
                );
              },
            ),
          );
        }

        // Show initial state with progressive loading hints
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dashboard_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Please wait while we load your data'),
            ],
          ),
        );
      },
    );
  }
}
