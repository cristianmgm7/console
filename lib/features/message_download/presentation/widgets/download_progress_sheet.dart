import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet that displays download progress
class DownloadProgressSheet extends StatelessWidget {
  const DownloadProgressSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, state) {
        // Auto-dismiss on completion or error
        if (state is DownloadCompleted || state is DownloadCancelled) {
          // Show summary snackbar
          if (state is DownloadCompleted) {
            final message = '✓ ${state.successCount} downloaded, '
                '${state.failureCount} failed, '
                '${state.skippedCount} skipped';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
            );
          } else if (state is DownloadCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download cancelled'), duration: Duration(seconds: 2)),
            );
          }

          // Dismiss sheet after brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading Messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (state is DownloadInProgress)
                    TextButton(
                      onPressed: () {
                        context.read<DownloadBloc>().add(const CancelDownload());
                      },
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Content based on state
              if (state is DownloadInProgress) ...[
                // Progress indicator
                LinearProgressIndicator(
                  value: state.progressPercent / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),

                // Progress text
                Text(
                  'Downloading ${state.current} of ${state.total} items',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.progressPercent.toStringAsFixed(0)}% complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (state is DownloadCompleted) ...[
                // Completion summary
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.successCount} successful, ${state.failureCount} failed, ${state.skippedCount} skipped',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else if (state is DownloadCancelled) ...[
                // Cancellation notice
                Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Cancelled',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed ${state.completedCount} of ${state.totalCount} items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else if (state is DownloadError) ...[
                // Error display
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
