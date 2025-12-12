import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_visualization.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Publish Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Visualization (now handles all states internally)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 200),
                  child: PreviewVisualization(),
                ),
                const SizedBox(height: 32),

                // Publish button (needs to be handled separately since it depends on state)
                BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
                  builder: (context, state) {
                    final canPublish = state is PreviewComposerLoaded && state.isValidSelection;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.publish),
                        label: const Text('Publish Preview'),
                        onPressed: canPublish
                            ? () {
                                context.read<PreviewComposerBloc>().add(
                                  const PreviewPublishRequested(),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
