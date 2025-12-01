import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CircularDownloadProgressWidget extends StatelessWidget {
  const CircularDownloadProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        return switch (state) {
          DownloadInProgress() => _buildProgressIndicator(context, state),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context, DownloadInProgress state) {
    return GestureDetector(
      onTap: () {
        // Show confirmation dialog before cancelling
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancel Download'),
            content: const Text('Are you sure you want to cancel the download?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  context.read<DownloadBloc>().add(const CancelDownload());
                  Navigator.pop(dialogContext);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress
            CircularProgressIndicator(
              value: state.progressPercent / 100,
              strokeWidth: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            // Cancel icon overlay
            Icon(
              AppIcons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
            // Percentage text
            Text(
              '${state.progressPercent.round()}%',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
