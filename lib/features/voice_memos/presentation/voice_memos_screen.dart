import 'package:carbon_voice_console/features/dashboard/presentation/components/message_card.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:flutter/material.dart';

class VoiceMemosScreen extends StatefulWidget {
  const VoiceMemosScreen({super.key});

  @override
  State<VoiceMemosScreen> createState() => _VoiceMemosScreenState();
}

class _VoiceMemosScreenState extends State<VoiceMemosScreen> {
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;


  // Dummy data
  final List<MessageUiModel> _messages = [
    MessageUiModel(
      id: '1',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 26, 15, 45),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(seconds: 18),
      audioModels: [],
      textModels: [],
      status: 'Processed',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Quick team standup notes and action items.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Quick team standup notes and action items.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '2',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 26, 14, 10),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 1, seconds: 23),
      audioModels: [],
      textModels: [],
      status: 'New',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Client feedback and feature requests discussion.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Client feedback and feature requests discussion.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '3',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 26, 11, 55),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(seconds: 42),
      audioModels: [],
      textModels: [],
      status: 'Processed',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Product roadmap planning for next quarter.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Product roadmap planning for next quarter.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '4',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 25, 9, 30),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 12, seconds: 31),
      audioModels: [],
      textModels: [],
      status: 'Processed',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Design review and UI/UX feedback session.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Design review and UI/UX feedback session.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '5',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 26, 8, 55),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 8, seconds: 55),
      audioModels: [],
      textModels: [],
      status: 'New',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Bug triage and priority discussion.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Bug triage and priority discussion.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '6',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 24, 16, 20),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 45, seconds: 2),
      audioModels: [],
      textModels: [],
      status: 'Archived',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Interview notes and candidate evaluation.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Interview notes and candidate evaluation.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '7',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 23, 14, 15),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 18, seconds: 42),
      audioModels: [],
      textModels: [],
      status: 'Processed',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Sprint retrospective and improvement ideas.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Sprint retrospective and improvement ideas.',
      transcriptText: null,
      audioUrl: null,
    ),
    MessageUiModel(
      id: '8',
      creatorId: 'user-1',
      createdAt: DateTime(2023, 10, 22, 10, 45),
      workspaceIds: ['workspace-1'],
      channelIds: ['conv-1'],
      duration: const Duration(minutes: 32, seconds: 18),
      audioModels: [],
      textModels: [],
      status: 'Processed',
      type: 'channel',
      lastHeardAt: null,
      heardDuration: null,
      totalHeardDuration: null,
      isTextMessage: false,
      notes: 'Technical architecture discussion and decisions.',
      lastUpdatedAt: null,
      conversationId: 'conv-1',
      userId: 'user-1',
      text: 'Technical architecture discussion and decisions.',
      transcriptText: null,
      audioUrl: null,
    ),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedMessages.addAll(_messages.map((m) => m.id));
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
      _selectAll = _selectedMessages.length == _messages.length;
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
              // Table Header
              Padding(
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
                        onChanged: _toggleSelectAll,
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
              ),

              // Messages List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageCard(
                        message: message,
                        isSelected: _selectedMessages.contains(message.id),
                        onSelected: (value) => _toggleMessageSelection(message.id, value),
                      );
                    },
                  ),
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
                  onDownloadAudio: () {
                    // TODO: Implement download audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading audio for ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onDownloadTranscript: () {
                    // TODO: Implement download transcript
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading transcripts for ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onSummarize: () {
                    // TODO: Implement summarize
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Summarizing ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onAIChat: () {
                    // TODO: Implement AI chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Opening AI chat for ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
