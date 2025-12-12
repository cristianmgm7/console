import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreviewPublishButton extends StatelessWidget {
  const PreviewPublishButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
      builder: (context, state) {
        final canPublish = state is PreviewComposerLoaded && state.isValidSelection;

        return SizedBox(
          width: double.infinity,
          child: AppButton(
            onPressed: canPublish
                ? () {
                    context.read<PreviewComposerBloc>().add(
                      const PreviewPublishRequested(),
                    );
                  }
                : null,
            fullWidth: true,
            size: AppButtonSize.large,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.publish),
                SizedBox(width: 8),
                Text('Publish Preview'),
              ],
            ),
          ),
        );
      },
    );
  }
}
