import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_gradients.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/preview_visualization.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_publish_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview
/// Receives conversationId and messageIds as parameters
class PreviewComposerScreen extends StatelessWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    required this.messageIds,
    super.key,
  });

  final String conversationId;
  final List<String> messageIds;

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
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.darkAura,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Publish Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Visualization (now handles all states internally)
                PreviewVisualization(),
                SizedBox(height: 16),
                // Publish button (uses themed AppButton with state management)
                PreviewPublishButton(),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

}
