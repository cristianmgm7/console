import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_bloc.dart';
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
    return BlocProvider(
      create: (_) => getIt<MessageDetailBloc>()..add(LoadMessageDetail(messageId)),
      child: BlocBuilder<MessageDetailBloc, MessageDetailState>(
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
      ),
    );
  }

  Widget _buildContent(MessageDetailState state) {
    if (state is MessageDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MessageDetailLoaded) {
      return MessageDetailContent(state: state);
    }
    if (state is MessageDetailError) {
      return Center(child: Text('Error: ${state.message}'));
    }
    return const SizedBox.shrink();
  }
}
