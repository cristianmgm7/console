import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_mini_player_widget.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/widgets/circular_download_progress_widget.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_bloc.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_event.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceMemosScreen extends StatefulWidget {
  const VoiceMemosScreen({super.key});

  @override
  State<VoiceMemosScreen> createState() => _VoiceMemosScreenState();
}

class _VoiceMemosScreenState extends State<VoiceMemosScreen> {
  final Set<String> _selectedVoiceMemos = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Load voice memos when screen initializes
    context.read<VoiceMemoBloc>().add(const LoadVoiceMemos());
  }

  void _toggleSelectAll(bool? value, int totalCount) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Get all voice memo IDs from current state
        final state = context.read<VoiceMemoBloc>().state;
        if (state is VoiceMemoLoaded) {
          _selectedVoiceMemos.addAll(state.voiceMemos.map((vm) => vm.id));
        }
      } else {
        _selectedVoiceMemos.clear();
      }
    });
  }

  void _toggleVoiceMemoSelection(String voiceMemoId, bool? value, int totalCount) {
    setState(() {
      if (value ?? false) {
        _selectedVoiceMemos.add(voiceMemoId);
      } else {
        _selectedVoiceMemos.remove(voiceMemoId);
      }
      _selectAll = _selectedVoiceMemos.length == totalCount;
    });
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      backgroundColor: AppColors.surface,
      child: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, downloadState) {
          return Stack(
            children: [
              BlocBuilder<VoiceMemoBloc, VoiceMemoState>(
                builder: _buildContent,
              ),

              // Floating Action Panel
              if (_selectedVoiceMemos.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MessagesActionPanel(
                      selectedCount: _selectedVoiceMemos.length,
                      onCancel: () {
                        setState(() {
                          _selectedVoiceMemos.clear();
                          _selectAll = false;
                        });
                      },
                      onDownloadAudio: () {
                        context.read<DownloadBloc>().add(
                          StartDownloadAudio(_selectedVoiceMemos),
                        );
                        setState(() {
                          _selectedVoiceMemos.clear();
                          _selectAll = false;
                        });
                      },
                      onDownloadTranscript: () {
                        context.read<DownloadBloc>().add(
                          StartDownloadTranscripts(_selectedVoiceMemos),
                        );
                        setState(() {
                          _selectedVoiceMemos.clear();
                          _selectAll = false;
                        });
                      },
                      onSummarize: () {
                        // TODO: Implement summarize
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Summarizing ${_selectedVoiceMemos.length} voice memos...',
                            ),
                          ),
                        );
                      },
                      onAIChat: () {
                        // TODO: Implement AI chat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening AI chat for ${_selectedVoiceMemos.length} voice memos...',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

            // Mini player - show when audio is ready
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                final bottomOffset = _selectedVoiceMemos.isNotEmpty ? 100.0 : 24.0;
                return Positioned(
                  bottom: bottomOffset,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: AudioMiniPlayerWidget(),
                  ),
                );
              },
            ),

            // Right-side circular progress indicator
            const Positioned(
              top: 24,
              right: 24,
              child: CircularDownloadProgressWidget(),
            ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, VoiceMemoState state) {
    // Loading state
    if (state is VoiceMemoLoading) {
      return const Center(child: AppProgressIndicator());
    }

    // Error state
    if (state is VoiceMemoError) {
      return AppEmptyState.error(
        message: state.message,
        onRetry: () {
          context.read<VoiceMemoBloc>().add(const LoadVoiceMemos(forceRefresh: true));
        },
      );
    }

    // Loaded state
    if (state is VoiceMemoLoaded) {
      if (state.voiceMemos.isEmpty) {
        return AppEmptyState.noMessages(
          onRetry: () {
            context.read<VoiceMemoBloc>().add(const LoadVoiceMemos(forceRefresh: true));
          },
        );
      }

      return AppTable(
        selectAll: _selectAll,
        onSelectAllChanged: (value) => _toggleSelectAll(value, state.voiceMemos.length),
        columns: const [
          AppTableColumn(
            title: 'Date',
            width: FixedColumnWidth(120),
          ),
          AppTableColumn(
            title: 'Duration',
            width: FixedColumnWidth(80),
          ),
          AppTableColumn(
            title: 'Play',
            width: FixedColumnWidth(80),
          ),
          AppTableColumn(
            title: 'Summary',
            width: FlexColumnWidth(),
          ),
          AppTableColumn(
            title: 'Status',
            width: FixedColumnWidth(100),
          ),
          AppTableColumn(
            title: 'Actions',
            width: FixedColumnWidth(100),
          ),
        ],
        rows: state.voiceMemos.map((voiceMemo) {
          return AppTableRow(
            selected: _selectedVoiceMemos.contains(voiceMemo.id),
            onSelectChanged: (selected) => _toggleVoiceMemoSelection(
              voiceMemo.id,
              selected,
              state.voiceMemos.length,
            ),
            cells: [
              // Date
              Text(
                _formatDate(voiceMemo.createdAt),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Duration
              Text(
                _formatDuration(voiceMemo.duration),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Playback
              if (voiceMemo.hasPlayableAudio)
                AppIconButton(
                  icon: AppIcons.play,
                  tooltip: 'Play audio',
                  onPressed: () {
                    final audioBloc = context.read<AudioPlayerBloc>();
                    final audioModel = voiceMemo.playableAudioModel;
                    if (audioModel != null) {
                      // Load audio - the BLoC will automatically start playback
                      audioBloc.add(LoadAudio(
                        messageId: voiceMemo.id,
                        audioModel: audioModel,
                      ));
                    }
                  },
                  size: AppIconButtonSize.small,
                )
              else
                const SizedBox.shrink(),

              // Summary
              Text(
                voiceMemo.displayText,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Status
              Text(
                voiceMemo.status,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Actions
              AppIconButton(
                icon: AppIcons.download,
                tooltip: 'Download',
                onPressed: () {
                  // TODO: Implement download
                },
                size: AppIconButtonSize.small,
              ),
            ],
          );
        }).toList(),
      );
    }

    // Initial state
    return AppEmptyState.loading();
  }
}
