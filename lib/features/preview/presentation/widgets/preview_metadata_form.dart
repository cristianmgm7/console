import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Display widget for preview metadata (read-only)
class PreviewMetadataDisplay extends StatelessWidget {
  const PreviewMetadataDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
      builder: (context, state) {
        if (state is! PreviewComposerLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview Details',
                style: AppTextStyle.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Title',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.currentMetadata.title,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Description',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.currentMetadata.description,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Cover image URL (if present)
              if (state.currentMetadata.coverImageUrl != null &&
                  state.currentMetadata.coverImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Cover Image',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.currentMetadata.coverImageUrl!,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
