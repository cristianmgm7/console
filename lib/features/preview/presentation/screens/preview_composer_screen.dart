import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview
/// Receives conversationId and messageIds as parameters, fetches own data
class PreviewComposerScreen extends StatefulWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    required this.messageIds,
    super.key,
  });

  final String conversationId;
  final List<String> messageIds;

  @override
  State<PreviewComposerScreen> createState() => _PreviewComposerScreenState();
}

class _PreviewComposerScreenState extends State<PreviewComposerScreen> {
  @override
  void initState() {
    super.initState();

    // Start the BLoC - it will fetch conversation and message data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreviewComposerBloc>().add(
            PreviewComposerStarted(
              conversationId: widget.conversationId,
              messageIds: widget.messageIds,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreviewComposerBloc, PreviewComposerState>(
      listener: (context, state) {
        // Listen for publish success
        if (state is PreviewComposerPublishSuccess) {
          // Navigate to confirmation screen
          context.go(
            '${AppRoutes.previewConfirmation}?url=${Uri.encodeComponent(state.previewUrl)}',
          );

          // Reset BLoC state
          context.read<PreviewComposerBloc>().add(const PreviewComposerReset());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
            builder: (context, state) {
              return switch (state) {
                PreviewComposerInitial() => const Center(
                    child: Text('Initializing...'),
                  ),
                PreviewComposerLoading() => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading conversation details...'),
                      ],
                    ),
                  ),
                PreviewComposerError(message: final message) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go(AppRoutes.dashboard),
                          child: const Text('Back to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                PreviewComposerLoaded() => _buildLoadedView(context, state),
                PreviewComposerPublishing() => _buildPublishingView(context, state),
                PreviewComposerPublishSuccess() => const Center(
                    child: CircularProgressIndicator(),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    PreviewComposerLoaded state,
  ) {
    final selectedCount = state.composerData.selectedMessages.length;
    final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversation info
          Text(
            'Creating preview for:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            state.composerData.conversation.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Selection counter
          MessageSelectionCounter(
            selectedCount: selectedCount,
            minCount: 3,
            maxCount: 5,
          ),

          if (!isValidSelection) ...[
            const SizedBox(height: 8),
            Text(
              'Please select between 3 and 5 messages.',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.publish),
              label: const Text('Publish Preview'),
              onPressed: isValidSelection && state.isValid
                  ? () {
                      context.read<PreviewComposerBloc>().add(
                            const PreviewPublishRequested(),
                          );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishingView(
    BuildContext context,
    PreviewComposerPublishing state,
  ) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Publishing preview...'),
        ],
      ),
    );
  }
}
