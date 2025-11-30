import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
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
              SnackBar(content: Text(message)),
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
        return AppContainer(
          padding: const EdgeInsets.all(24),
          backgroundColor: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  if (state is DownloadInProgress)
                    AppTextButton(
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
                AppProgressIndicator(
                  type: AppProgressIndicatorType.linear,
                  size: AppProgressIndicatorSize.large,
                  value: state.progressPercent / 100,
                ),
                const SizedBox(height: 16),

                // Progress text
                Text(
                  'Downloading ${state.current} of ${state.total} items',
                  style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.progressPercent.toStringAsFixed(0)}% complete',
                  style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ] else if (state is DownloadCompleted) ...[
                // Completion summary
                Icon(
                  AppIcons.checkCircle,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Complete',
                  style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.successCount} successful, ${state.failureCount} failed, ${state.skippedCount} skipped',
                  style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ] else if (state is DownloadCancelled) ...[
                // Cancellation notice
                Icon(
                  AppIcons.cancel,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Cancelled',
                  style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed ${state.completedCount} of ${state.totalCount} items',
                  style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ] else if (state is DownloadError) ...[
                // Error display
                Icon(
                  AppIcons.error,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
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
