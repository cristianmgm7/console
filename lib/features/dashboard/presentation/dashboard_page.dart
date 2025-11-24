import 'package:flutter/material.dart';
import '../models/audio_message.dart';
import 'components/message_card.dart';
import 'components/messages_action_panel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedWorkspace = 'Personal';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;

  // Dummy data
  final List<AudioMessage> _messages = [
    AudioMessage(
      id: '1',
      date: DateTime(2023, 10, 26, 15, 45),
      owner: 'Travis Bogard',
      message: 'Some cool stuff in about a message here.',
      duration: const Duration(minutes: 0, seconds: 18),
      status: 'Processed',
      project: 'Project Phoenix',
    ),
    AudioMessage(
      id: '2',
      date: DateTime(2023, 10, 26, 14, 10),
      owner: 'Jane Doe',
      message: 'Discussing the quarterly results and planning for the next phase of th...',
      duration: const Duration(minutes: 1, seconds: 23),
      status: 'New',
      project: 'Internal Sprint',
    ),
    AudioMessage(
      id: '3',
      date: DateTime(2023, 10, 26, 11, 55),
      owner: 'John Smith',
      message: 'Following up on the action items from the previous meeting.',
      duration: const Duration(minutes: 0, seconds: 42),
      status: 'Processed',
      project: 'Project Phoenix',
    ),
    AudioMessage(
      id: '4',
      date: DateTime(2023, 10, 25, 9, 30),
      owner: 'Sarah Johnson',
      message: 'Client Call - Q3 Strategy review and discussion about upcoming initiatives.',
      duration: const Duration(minutes: 12, seconds: 31),
      status: 'Processed',
      project: 'Project Phoenix',
    ),
    AudioMessage(
      id: '5',
      date: DateTime(2023, 10, 26, 8, 55),
      owner: 'Mike Chen',
      message: 'Daily Standup Recording - team updates and blockers discussion.',
      duration: const Duration(minutes: 8, seconds: 55),
      status: 'New',
      project: 'Internal Sprint',
    ),
    AudioMessage(
      id: '6',
      date: DateTime(2023, 10, 24, 16, 20),
      owner: 'Emily Parker',
      message: 'Onboarding Interview #12 - discussing role expectations and team culture.',
      duration: const Duration(minutes: 45, seconds: 2),
      status: 'Archived',
      project: 'HR Initiatives',
    ),
    AudioMessage(
      id: '7',
      date: DateTime(2023, 10, 23, 14, 15),
      owner: 'Alex Rodriguez',
      message: 'Product Demo - v2.1 feature walkthrough and feedback session.',
      duration: const Duration(minutes: 18, seconds: 42),
      status: 'Processed',
      project: 'Project Chimera',
    ),
    AudioMessage(
      id: '8',
      date: DateTime(2023, 10, 22, 10, 45),
      owner: 'Lisa Wong',
      message: 'Architecture review meeting - discussing microservices migration strategy.',
      duration: const Duration(minutes: 32, seconds: 18),
      status: 'Processed',
      project: 'Tech Infrastructure',
    ),
    AudioMessage(
      id: '9',
      date: DateTime(2023, 10, 21, 13, 30),
      owner: 'David Kim',
      message: 'Customer feedback session - analyzing user pain points and feature requests.',
      duration: const Duration(minutes: 25, seconds: 10),
      status: 'New',
      project: 'Product Research',
    ),
    AudioMessage(
      id: '10',
      date: DateTime(2023, 10, 20, 11, 0),
      owner: 'Amanda Torres',
      message: 'Budget planning discussion - Q4 allocation and resource optimization.',
      duration: const Duration(minutes: 28, seconds: 33),
      status: 'Processed',
      project: 'Finance Review',
    ),
    AudioMessage(
      id: '11',
      date: DateTime(2023, 10, 19, 15, 15),
      owner: 'Robert Lee',
      message: 'Security audit findings - critical vulnerabilities and remediation plan.',
      duration: const Duration(minutes: 19, seconds: 47),
      status: 'Processed',
      project: 'Security Operations',
    ),
    AudioMessage(
      id: '12',
      date: DateTime(2023, 10, 18, 9, 20),
      owner: 'Jennifer Martinez',
      message: 'Marketing campaign review - analyzing metrics and ROI for recent initiatives.',
      duration: const Duration(minutes: 22, seconds: 5),
      status: 'Archived',
      project: 'Marketing Strategy',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedWorkspace,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      'Personal',
                      'Work',
                      'Side Project',
                      'Research',
                      'Client Work',
                    ].map((String workspace) {
                      return DropdownMenuItem<String>(
                        value: workspace,
                        child: Text(workspace),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWorkspace = newValue!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Search Field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
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
                ),
                
                const Spacer(),
                                
                // Add New Button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add new message
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filters Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                const Text('Search by name, project...'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Status'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('Project'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Date Range'),
                ),
              ],
            ),
          ),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          
          // Messages List
          Expanded(
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
          
          // // Pagination
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 16.0),
          //   decoration: BoxDecoration(
          //     color: Theme.of(context).colorScheme.surface,
          //     border: Border(
          //       top: BorderSide(
          //         color: Theme.of(context).dividerColor,
          //       ),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       IconButton(
          //         icon: const Icon(Icons.chevron_left),
          //         onPressed: () {
          //           // TODO: Previous page
          //         },
          //       ),
          //       const SizedBox(width: 16),
          //       Text(
          //         'Page 1 of 12',
          //         style: Theme.of(context).textTheme.bodyMedium,
          //       ),
          //       const SizedBox(width: 16),
          //       IconButton(
          //         icon: const Icon(Icons.chevron_right),
          //         onPressed: () {
          //           // TODO: Next page
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
      
      // Floating Action Panel
      floatingActionButton: MessagesActionPanel(
        selectedCount: _selectedMessages.length,
        onDownload: () {
          // TODO: Implement download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${_selectedMessages.length} messages...'),
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
              content: Text('Opening AI chat for ${_selectedMessages.length} messages...'),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
