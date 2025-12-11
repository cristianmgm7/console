import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview (UI demo version)
class PreviewComposerScreen extends StatefulWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  State<PreviewComposerScreen> createState() => _PreviewComposerScreenState();
}

class _PreviewComposerScreenState extends State<PreviewComposerScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize composer with conversation data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conversationState = context.read<ConversationBloc>().state;

      if (conversationState is ConversationLoaded) {
        final conversation = conversationState.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => conversationState.conversations.first,
        );

        context.read<PreviewComposerCubit>().initialize(
              conversationTitle: conversation.name,
              conversationDescription: conversation.description,
              conversationImageUrl: conversation.imageUrl,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreviewComposerCubit, PreviewComposerState>(
      listener: (context, state) {
        // Listen for mock publish completion
        if (state.mockPreviewUrl != null && !state.isPublishing) {
          // Navigate to confirmation screen
          context.go(
            '${AppRoutes.previewConfirmation}?url=${Uri.encodeComponent(state.mockPreviewUrl!)}',
          );

          // Reset state
          context.read<PreviewComposerCubit>().reset();
          context.read<MessageSelectionCubit>().clearSelection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Preview (Demo)'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
            builder: (context, selectionState) {
              final selectedCount = selectionState.selectedCount;
              final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'UI Demo Mode: No backend integration. Mock data only.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selection counter
                    MessageSelectionCounter(
                      selectedCount: selectedCount,
                      minCount: 3,
                      maxCount: 5,
                    ),

                    if (!isValidSelection) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Please select between 3 and 5 messages to include in your preview.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Form title
                    Text(
                      'Preview Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Metadata form
                    const PreviewMetadataForm(),
                    const SizedBox(height: 32),

                    // Publish button
                    BlocBuilder<PreviewComposerCubit, PreviewComposerState>(
                      builder: (context, composerState) {
                        final isPublishing = composerState.isPublishing;
                        final canPublish = isValidSelection &&
                            composerState.isValid &&
                            !isPublishing;

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: isPublishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.publish),
                            label: Text(
                              isPublishing
                                  ? 'Publishing...'
                                  : 'Publish Preview (Mock)',
                            ),
                            onPressed:
                                canPublish ? () => _handlePublish(context) : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePublish(BuildContext context) {
    // Validate form
    final isValid = context.read<PreviewComposerCubit>().validate();
    if (!isValid) return;

    // Get state
    final selectedMessageIds =
        context.read<MessageSelectionCubit>().getSelectedMessageIds();

    // Trigger mock publish
    context.read<PreviewComposerCubit>().mockPublish(
          conversationId: widget.conversationId,
          messageIds: selectedMessageIds.toList(),
        );
  }
}
