import 'dart:async';

import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/base_panel.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Side panel showing download progress with circular indicators
class DownloadPanel extends StatefulWidget {
  const DownloadPanel({super.key});

  @override
  State<DownloadPanel> createState() => _DownloadPanelState();
}

class _DownloadPanelState extends State<DownloadPanel> {
  Timer? _autoDismissTimer;

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss(DownloadState state) {
    // Cancel any existing timer
    _autoDismissTimer?.cancel();

    // Schedule auto-dismiss for completed/cancelled states
    if (state is DownloadCompleted || state is DownloadCancelled) {
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          // Reset BLoC to initial state (hides panel)
          context.read<DownloadBloc>().add(const ResetDownload());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, state) {
        _scheduleAutoDismiss(state);
      },
      builder: (context, state) {
        if (state is DownloadInitial) {
          return const SizedBox.shrink();
        }

        return BasePanel(
          child: Column(
            children: [
              // Header
              AppContainer(
                padding: const EdgeInsets.all(16),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.download, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Downloads',
                      style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    if (state is DownloadInProgress)
                      AppIconButton(
                        icon: AppIcons.close,
                        onPressed: () {
                          context.read<DownloadBloc>().add(const CancelDownload());
                        },
                        tooltip: 'Cancel',
                        size: AppIconButtonSize.small,
                      )
                    else
                      AppIconButton(
                        icon: AppIcons.close,
                        onPressed: () {
                          _autoDismissTimer?.cancel();
                          context.read<DownloadBloc>().add(const ResetDownload());
                        },
                        tooltip: 'Close',
                        size: AppIconButtonSize.small,
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

  Widget _buildContent(DownloadState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: switch (state) {
        DownloadInProgress() => _buildInProgress(state),
        DownloadCompleted() => _buildCompleted(state),
        DownloadCancelled() => _buildCancelled(state),
        DownloadError() => _buildError(state),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildInProgress(DownloadInProgress state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular progress indicator with percentage
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: state.progressPercent / 100,
                strokeWidth: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${state.progressPercent.toStringAsFixed(0)}%',
                  style: AppTextStyle.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${state.current} / ${state.total}',
                  style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Downloading files...',
          style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCompleted(DownloadCompleted state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.checkCircle, color: AppColors.primary, size: 64),
        const SizedBox(height: 16),
        Text(
          'Download Complete',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.successCount} successful',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        if (state.failureCount > 0)
          Text(
            '${state.failureCount} failed',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
          ),
        if (state.skippedCount > 0)
          Text(
            '${state.skippedCount} skipped',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildCancelled(DownloadCancelled state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.cancel, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          'Download Cancelled',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Completed ${state.completedCount} of ${state.totalCount}',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError(DownloadError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.error, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          'Error',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          state.message,
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
