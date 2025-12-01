import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_bloc.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_event.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_state.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
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
      child: Stack(
        children: [
          BlocBuilder<VoiceMemoBloc, VoiceMemoState>(
            builder: (context, state) {
              return _buildContent(context, state);
            },
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
                  onDownloadAudio: () {
                    // TODO: Implement download audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Downloading audio for ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
                  },
                  onDownloadTranscript: () {
                    // TODO: Implement download transcript
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Downloading transcripts for ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
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
        ],
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
            title: 'Name',
            width: FixedColumnWidth(150),
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
            width: FixedColumnWidth(120),
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

              // Name
              Text(
                voiceMemo.name ?? 'Untitled',
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (voiceMemo.hasPlayableAudio)
                    AppIconButton(
                      icon: AppIcons.play,
                      tooltip: 'Play audio',
                      onPressed: () {
                        // TODO: Implement audio playback
                      },
                      size: AppIconButtonSize.small,
                    ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () {
                      // TODO: Implement download
                    },
                    size: AppIconButtonSize.small,
                  ),
                ],
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
