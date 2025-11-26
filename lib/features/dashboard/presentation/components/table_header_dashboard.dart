import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:flutter/material.dart';

class DashboardTableHeader extends StatelessWidget {
  const DashboardTableHeader({
    required this.onToggleSelectAll, required this.messageState, required this.selectAll, super.key,
  });

  final MessageLoaded messageState;
  final bool selectAll;
  final void Function(int length, {bool? value}) onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
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
              value: selectAll,
              onChanged: (value) => onToggleSelectAll(messageState.messages.length, value: value),
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
}
