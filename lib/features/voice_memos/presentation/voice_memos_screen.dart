import 'package:flutter/material.dart';
import '../../dashboard/models/audio_message.dart';
import '../../dashboard/presentation/components/message_card.dart';
import '../../dashboard/presentation/components/messages_action_panel.dart';

class VoiceMemosScreen extends StatefulWidget {
  const VoiceMemosScreen({super.key});

  @override
  State<VoiceMemosScreen> createState() => _VoiceMemosScreenState();
}

class _VoiceMemosScreenState extends State<VoiceMemosScreen> {
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;

  // Dummy data
  final List<AudioMessage> _messages = [
    AudioMessage(
      id: '1',
      date: DateTime(2023, 10, 26, 15, 45),
      owner: 'Travis Bogard',
      message: 'Quick team standup notes and action items.',
      duration: const Duration(minutes: 0, seconds: 18),
      status: 'Processed',
      project: 'Team Updates',
    ),
    AudioMessage(
      id: '2',
      date: DateTime(2023, 10, 26, 14, 10),
      owner: 'Travis Bogard',
      message: 'Client feedback and feature requests discussion.',
      duration: const Duration(minutes: 1, seconds: 23),
      status: 'New',
      project: 'Client Work',
    ),
    AudioMessage(
      id: '3',
      date: DateTime(2023, 10, 26, 11, 55),
      owner: 'Travis Bogard',
      message: 'Product roadmap planning for next quarter.',
      duration: const Duration(minutes: 0, seconds: 42),
      status: 'Processed',
      project: 'Planning',
    ),
    AudioMessage(
      id: '4',
      date: DateTime(2023, 10, 25, 9, 30),
      owner: 'Travis Bogard',
      message: 'Design review and UI/UX feedback session.',
      duration: const Duration(minutes: 12, seconds: 31),
      status: 'Processed',
      project: 'Design',
    ),
    AudioMessage(
      id: '5',
      date: DateTime(2023, 10, 26, 8, 55),
      owner: 'Travis Bogard',
      message: 'Bug triage and priority discussion.',
      duration: const Duration(minutes: 8, seconds: 55),
      status: 'New',
      project: 'Development',
    ),
    AudioMessage(
      id: '6',
      date: DateTime(2023, 10, 24, 16, 20),
      owner: 'Travis Bogard',
      message: 'Interview notes and candidate evaluation.',
      duration: const Duration(minutes: 45, seconds: 2),
      status: 'Archived',
      project: 'HR',
    ),
    AudioMessage(
      id: '7',
      date: DateTime(2023, 10, 23, 14, 15),
      owner: 'Travis Bogard',
      message: 'Sprint retrospective and improvement ideas.',
      duration: const Duration(minutes: 18, seconds: 42),
      status: 'Processed',
      project: 'Agile Process',
    ),
    AudioMessage(
      id: '8',
      date: DateTime(2023, 10, 22, 10, 45),
      owner: 'Travis Bogard',
      message: 'Technical architecture discussion and decisions.',
      duration: const Duration(minutes: 32, seconds: 18),
      status: 'Processed',
      project: 'Architecture',
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
      if (value == true) {
        _selectedMessages.add(messageId);
      } else {
        _selectedMessages.remove(messageId);
      }
      _selectAll = _selectedMessages.length == _messages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          Column(
            children: [
              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Text(
                          'Message',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  padding: const EdgeInsets.symmetric(horizontal: 64.0),
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageCard(
                        message: message,
                        isSelected: _selectedMessages.contains(message.id),
                        onSelected: (value) =>
                            _toggleMessageSelection(message.id, value),
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
                  onDownload: () {
                    // TODO: Implement download
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Downloading ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onSummarize: () {
                    // TODO: Implement summarize
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Summarizing ${_selectedMessages.length} messages...'),
                      ),
                    );
                  },
                  onAIChat: () {
                    // TODO: Implement AI chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Opening AI chat for ${_selectedMessages.length} messages...'),
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
