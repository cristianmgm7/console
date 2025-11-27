import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailView extends StatelessWidget {
  const MessageDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageDetailBloc, MessageDetailState>(
      builder: (context, state) {
        if (state is MessageDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MessageDetailLoaded) {
          return _buildDetailContent(context, state);
        }
        if (state is MessageDetailError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDetailContent(BuildContext context, MessageDetailLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info section
          _buildBasicInfoSection(state),
          const SizedBox(height: 24),
          // Content section
          _buildContentSection(state),
          const SizedBox(height: 24),
          // Metadata section
          _buildMetadataSection(state),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(MessageDetailLoaded state) {
    final message = state.message;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', message.id),
            _buildInfoRow('Creator', message.creatorId),
            _buildInfoRow('Created', _formatDate(message.createdAt)),
            _buildInfoRow('Duration', _formatDuration(message.duration)),
            _buildInfoRow('Status', message.status),
            _buildInfoRow('Type', message.type),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(MessageDetailLoaded state) {
    final message = state.message;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (message.transcriptText != null) ...[
              const Text(
                'Transcript',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(message.transcriptText!),
              const SizedBox(height: 16),
            ],
            if (message.text != null) ...[
              const Text(
                'Text',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(message.text!),
            ],
            if (message.audioUrl != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Audio URL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SelectableText(message.audioUrl!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(MessageDetailLoaded state) {
    final message = state.message;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (message.lastHeardAt != null)
              _buildInfoRow('Last Heard', _formatDate(message.lastHeardAt!)),
            if (message.heardDuration != null)
              _buildInfoRow('Heard Duration',
                  _formatDuration(message.heardDuration!),
              ),
            if (message.totalHeardDuration != null)
              _buildInfoRow('Total Heard Duration',
                  _formatDuration(message.totalHeardDuration!),
              ),
            if (message.lastUpdatedAt != null)
              _buildInfoRow('Last Updated',
                  _formatDate(message.lastUpdatedAt!),
              ),
            _buildInfoRow('Workspace IDs',
                message.workspaceIds.join(', '),
            ),
            _buildInfoRow('Channel IDs',
                message.channelIds.join(', '),
            ),
            _buildInfoRow('Conversation ID', message.conversationId),
            _buildInfoRow('User ID', message.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
