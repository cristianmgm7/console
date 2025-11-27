import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/components/message_detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({
    required this.messageId,
    required this.onClose,
    super.key,
  });

  final String messageId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Trigger loading the message detail when panel is shown
    context.read<MessageBloc>().add(LoadMessageDetail(messageId));

    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, state) {
        return Container(
          width: 400, // Fixed width panel
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Message Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _buildContent(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(MessageState state) {
    if (state is MessageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MessageDetailLoaded) {
      return MessageDetailContent(state: state);
    }
    if (state is MessageError) {
      return Center(child: Text('Error: ${state.message}'));
    }
    return const SizedBox.shrink();
  }
}
