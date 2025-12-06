import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_mini_player_widget.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioMiniPlayerPositioned extends StatelessWidget {
  const AudioMiniPlayerPositioned({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageCompositionCubit, MessageCompositionState>(
      builder: (context, compositionState) {
        return Positioned(
          bottom: compositionState.isVisible && compositionState.canCompose
              ? 210  // Move up when composition panel is open (~150px panel + ~30px spacing)
              : 24,  // Normal position
          left: 0,
          right: 0,
          child: const Center(
            child: AudioMiniPlayerWidget(),
          ),
        );
      },
    );
  }
}
