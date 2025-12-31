import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Example widget demonstrating how to render the polymorphic ChatItem list.
///
/// This example shows the pattern matching approach using Dart's switch expressions
/// to handle different ChatItem types with type safety.
class ChatItemListExample extends StatelessWidget {
  const ChatItemListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is! ChatLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: state.items.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final item = state.items[index];

            // Pattern matching on sealed class - compile-time exhaustiveness checking!
            return switch (item) {
              TextMessageItem() => _buildTextMessage(context, item),
              AuthRequestItem() => _buildAuthRequest(context, item),
              SystemStatusItem() => _buildSystemStatus(context, item),
            };
          },
        );
      },
    );
  }

  /// Build a text message bubble
  Widget _buildTextMessage(BuildContext context, TextMessageItem item) {
    final isUser = item.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.subAgentName != null)
                Text(
                  item.subAgentName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                item.text,
                style: const TextStyle(fontSize: 14),
              ),
              if (item.isPartial)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build an authentication request card
  Widget _buildAuthRequest(BuildContext context, AuthRequestItem item) {
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
                  const Text(
                    'Authentication Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The agent needs to authenticate with ${item.request.provider ?? "a service"} to continue.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement authentication flow
                  // The ChatBloc already forwards auth requests to McpAuthBloc
                  // This button could open the auth URL directly:
                  // launchUrl(Uri.parse(item.request.correctedAuthUri));
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Authenticate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a system status indicator
  Widget _buildSystemStatus(BuildContext context, SystemStatusItem item) {
    // Choose icon and color based on status type
    final (icon, color) = switch (item.type) {
      StatusType.thinking => (Icons.psychology, Colors.blue),
      StatusType.toolCall => (Icons.build, Colors.purple),
      StatusType.handoff => (Icons.swap_horiz, Colors.orange),
      StatusType.error => (Icons.error, Colors.red),
      StatusType.complete => (Icons.check_circle, Colors.green),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                item.status,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.type == StatusType.thinking || item.type == StatusType.toolCall)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
