import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/audio_player_panel.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/download_panel.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/components/message_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Orchestrates all side panels in the dashboard
class DashboardPanels extends StatelessWidget {
  const DashboardPanels({
    required this.selectedMessageForDetail,
    required this.onCloseDetail,
    super.key,
  });

  final String? selectedMessageForDetail;
  final VoidCallback onCloseDetail;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Download Panel (Right-most)
        BlocBuilder<DownloadBloc, DownloadState>(
          builder: (context, state) {
            final showDownloadPanel = state is DownloadInProgress ||
                                       state is DownloadCompleted ||
                                       state is DownloadCancelled;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              right: showDownloadPanel ? 0 : -350, // Slide from right
              bottom: 0,
              width: 320,
              child: const DownloadPanel(),
            );
          },
        ),

        // Message Detail Panel (Center-right)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          right: selectedMessageForDetail != null ? 320 : -400, // Offset by download panel width
          height: double.infinity,
          width: 400,
          child: selectedMessageForDetail != null
              ? MessageDetailPanel(
                  messageId: selectedMessageForDetail!,
                  onClose: onCloseDetail,
                )
              : const SizedBox.shrink(),
        ),

        // Audio Player Panel (Center-right, below detail)
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            final showAudioPanel = state is AudioPlayerReady || state is AudioPlayerLoading;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: selectedMessageForDetail != null ? 420 : 80, // Position below detail if present
              right: showAudioPanel ? 320 : -420, // Offset by download panel width
              height: 340, // Fixed max height, panel controls internal sizing
              width: 400,
              child: const AudioPlayerPanel(),
            );
          },
        ),
      ],
    );
  }
}
