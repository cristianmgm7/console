import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/conversation_header_section.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/messages_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget that visualizes how the preview will look to end users
/// Displays conversation metadata, participants, statistics, and messages
class PreviewVisualization extends StatelessWidget {
  const PreviewVisualization({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
      builder: (context, state) {
        return switch (state) {
          PreviewComposerInitial() => _buildInitialState(),
          PreviewComposerLoading() => _buildLoadingState(),
          PreviewComposerError(message: final message) => _buildErrorState(message),
          PreviewComposerLoaded() => _buildLoadedState(context, state),
          PreviewComposerPublishing() => _buildPublishingState(),
          PreviewComposerPublishSuccess() => _buildPublishSuccessState(),
        };
      },
    );
  }

  Widget _buildInitialState() => const Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text('Initializing preview...'),
      ),
    ),
  );

  Widget _buildLoadingState() => const Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading conversation details...'),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorState(String message) => Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyle.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyle.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
              ),
            ),
  );

  Widget _buildLoadedState(BuildContext context, PreviewComposerLoaded state) {
    return Card(
      color: AppColors.background,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Conversation header section (now includes participants and statistics)
            ConversationHeaderSection(
              conversation: state.conversation,
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.divider),

            // Messages section
            MessagesSection(
              messages: state.selectedMessages,
              conversation: state.conversation,
              parentMessages: state.parentMessages,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishingState() => const Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Publishing preview...'),
      ],
        ),
      ),
    ),
  );

  Widget _buildPublishSuccessState() => const Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
    );

}
