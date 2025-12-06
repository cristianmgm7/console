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
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular progress
                CircularProgressIndicator(
                  value: state.progressPercent / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                // Percentage text
                Text(
                  '${state.current} / ${state.total}',
                  style: AppTextStyle.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Cancel button below the circle
          GestureDetector(
            onTap: () {
              context.read<DownloadBloc>().add(const CancelDownload());
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Icon(
                AppIcons.close,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
