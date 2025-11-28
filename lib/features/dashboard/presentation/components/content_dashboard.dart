import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/message_card.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart' as ws_events;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.scrollController,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    this.onViewDetail,
    super.key,
  });

  final ScrollController scrollController;
  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final ValueChanged<String>? onViewDetail;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, messageState) {
        // Show loading when any bloc is loading
        if (isAnyBlocLoading(context)) {
          return const Center(child: AppProgressIndicator());
        }

        if (messageState is MessageError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.error, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  messageState.message,
                  style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppButton(
                  onPressed: () {
                    // Retry by reloading workspaces
                    context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        // empty state
        if (messageState is MessageLoaded) {
          if (messageState.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.inbox, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No messages',
                    style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No messages found in this conversation',
                    style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: ListView.builder(
              controller: scrollController,
              itemCount: messageState.messages.length + (messageState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messageState.messages.length) {
                  // Loading more indicator
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppProgressIndicator()),
                  );
                }

                final message = messageState.messages[index];

                return MessageCard(
                  message: message,
                  isSelected: selectedMessages.contains(message.id),
                  onSelected: (value) => onToggleMessageSelection(message.id, value: value),
                  onViewDetail: onViewDetail,
                );
              },
            ),
          );
        }

        // Show initial state with progressive loading hints
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.dashboard, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we load your data',
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
