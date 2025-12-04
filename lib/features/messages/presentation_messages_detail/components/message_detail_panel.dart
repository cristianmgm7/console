import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/components/message_detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({
    required this.messageId,
    required this.onClose,
    super.key,
  });

  final String messageId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageDetailBloc, MessageDetailState>(
      builder: (context, state) {
        return SizedBox(
          width: 400, // Fixed width panel
          height: double.infinity, // Fill available height
          child: AppContainer(
            border: const Border(
              left: BorderSide(
                color: AppColors.border,
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                AppContainer(
                  padding: const EdgeInsets.all(16),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Message Details',
                        style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: AppIcons.close,
                        onPressed: onClose,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildContent(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(MessageDetailState state) {
    if (state is MessageDetailLoading) {
      return const Center(child: AppProgressIndicator());
    }
    if (state is MessageDetailLoaded) {
      return MessageDetailContent(state: state);
    }
    if (state is MessageDetailError) {
      return Center(
        child: Text(
          'Error: ${state.message}',
          style: AppTextStyle.bodyLarge.copyWith(color: AppColors.error),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
