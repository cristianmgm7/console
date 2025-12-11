import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MessagesActionPanel extends StatelessWidget {
  const MessagesActionPanel({
    required this.onDownloadAudio,
    required this.onDownloadTranscript,
    required this.onSummarize,
    required this.onAIChat,
    super.key,
  });
  final VoidCallback onDownloadAudio;
  final VoidCallback onDownloadTranscript;
  final VoidCallback onSummarize;
  final VoidCallback onAIChat;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
      builder: (context, selectionState) {
        if (!selectionState.hasSelection) {
          return const SizedBox.shrink();
        }

        return GlassContainer(
          opacity: 0.2,
          width: 150,
          height: 170,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.checkCircle,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectionState.selectedCount}',
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 8),

            // Download Menu Button
            PopupMenuButton<String>(
              color: AppColors.surface,
              key: const Key('download_dropdown'),
              onSelected: (String value) {
                switch (value) {
                  case 'audio':
                    onDownloadAudio();
                  case 'transcript':
                    onDownloadTranscript();
                  case 'both':
                    onSummarize();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'audio',
                  child: Row(
                    children: [
                      Icon(AppIcons.audioTrack, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Audio',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'transcript',
                  child: Row(
                    children: [
                      Icon(AppIcons.message, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Transcript',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'both',
                  child: Row(
                    children: [
                      Icon(AppIcons.download, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Both',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 90,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AppIcons.download, size: 18, color: AppColors.primary),
              ),
            ),

                const SizedBox(height: 8),

                // Publish Preview Button (Demo)
                Builder(
                  builder: (context) {
                    final selectedCount = selectionState.selectedCount;
                    final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

                    return AppButton(
                      onPressed: isValidSelection ? () => _handlePublishPreview(context) : null,
                      backgroundColor: isValidSelection
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.disabled.withValues(alpha: 0.1),
                      foregroundColor: isValidSelection
                          ? AppColors.primary
                          : AppColors.disabled,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.share, size: 18),
                          const SizedBox(width: 8),
                          const Text('Preview'),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                // Cancel Button
                AppButton(
                  onPressed: () => context.read<MessageSelectionCubit>().clearSelection(),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.close, size: 18),
                      const SizedBox(width: 8),
                      const Text('Cancel'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePublishPreview(BuildContext context) {
    final selectionState = context.read<MessageSelectionCubit>().state;
    final selectedCount = selectionState.selectedCount;

    // Double-check validation
    if (selectedCount < 3 || selectedCount > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select between 3 and 5 messages for preview'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Get conversation ID
    final conversationState = context.read<ConversationBloc>().state;
    if (conversationState is ConversationLoaded &&
        conversationState.selectedConversationIds.isNotEmpty) {
      final conversationId = conversationState.selectedConversationIds.first;
      context.go('${AppRoutes.previewComposer}?conversationId=$conversationId');
    }
  }
}
