import 'package:flutter/material.dart';
import 'components/voice_memo_component.dart';

class VoiceMemosPage extends StatelessWidget {
  const VoiceMemosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample voice memos data
    final memos = List.generate(
      12,
      (index) => VoiceMemo(
        id: 'memo_$index',
        title: 'Voice Memo ${index + 1}',
        duration: Duration(minutes: 2 + index, seconds: 30),
        date: DateTime.now().subtract(Duration(days: index)),
        size: '2.${index}MB',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Memos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: memos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 100,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No voice memos yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start recording to create your first memo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: memos.length,
              itemBuilder: (context, index) {
                final memo = memos[index];
                return VoiceMemoComponent(memo: memo);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement record new memo
        },
        icon: const Icon(Icons.mic),
        label: const Text('Record'),
      ),
    );
  }
}

class VoiceMemo {
  final String id;
  final String title;
  final Duration duration;
  final DateTime date;
  final String size;

  VoiceMemo({
    required this.id,
    required this.title,
    required this.duration,
    required this.date,
    required this.size,
  });
}

