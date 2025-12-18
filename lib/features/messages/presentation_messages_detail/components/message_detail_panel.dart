import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/components/message_detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailPanel extends StatefulWidget {
  const MessageDetailPanel({
    required this.messageId,
    required this.onClose,
    super.key,
  });

  final String messageId;
  final VoidCallback onClose;

  @override
  State<MessageDetailPanel> createState() => _MessageDetailPanelState();
}

class _MessageDetailPanelState extends State<MessageDetailPanel> {
  @override
  void initState() {
    super.initState();
    // Trigger the bloc to load the message when the panel is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageDetailBloc>().add(LoadMessageDetail(widget.messageId));
    });
  }

  @override
  void didUpdateWidget(MessageDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the messageId changes, load the new message
    if (oldWidget.messageId != widget.messageId) {
      context.read<MessageDetailBloc>().add(LoadMessageDetail(widget.messageId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageDetailBloc, MessageDetailState>(
      builder: (context, state) {
        // Debug: Print current statetate: ${state.runtimeType}');
        if (state is MessageDetailLoaded) {}

        return SizedBox(
          width: 400,
          height: double.infinity,
          child: AppContainer(
            border: const Border(
              left: BorderSide(
                color: AppColors.border,
              ),
            ),
            child: Column(
              children: [
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
                        onPressed: widget.onClose,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildContentFromState(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentFromState(MessageDetailState state) {
    if (state is MessageDetailLoading) {
      return _buildLoadingState();
    }
    if (state is MessageDetailLoaded) {
      // Verify that the loaded message matches the current messageId
      if (state.message.id == widget.messageId) {
        return _buildLoadedState(state);
      }
      // If the message doesn't match, show loading while waiting for the correct message
      return _buildLoadingState();
    }
    if (state is MessageDetailError) {
      return _buildErrorState(state);
    }
    return _buildDefaultState();
  }

  Widget _buildErrorState(MessageDetailError state) {
    return Center(
      child: Text(
        'Error: ${state.message}',
        style: AppTextStyle.bodyLarge.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildDefaultState() => const SizedBox.shrink();

  Widget _buildLoadingState() => const Center(child: AppProgressIndicator());

  Widget _buildLoadedState(MessageDetailLoaded state) => MessageDetailContent(state: state);
}
