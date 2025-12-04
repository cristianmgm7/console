import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_icon_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_outlined_button.dart';
import 'package:carbon_voice_console/core/widgets/containers/glass_container.dart';
import 'package:carbon_voice_console/core/widgets/interactive/app_text_field.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReplyMessagePanel extends StatefulWidget {
  const ReplyMessagePanel({
    required this.workspaceId,
    required this.channelId,
    required this.replyToMessageId,
    this.onClose,
    this.onSuccess,
    super.key,
  });

  final String workspaceId;
  final String channelId;
  final String replyToMessageId;
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;

  @override
  State<ReplyMessagePanel> createState() => _ReplyMessagePanelState();
}

class _ReplyMessagePanelState extends State<ReplyMessagePanel> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return;
    }

    context.read<SendMessageBloc>().add(
          SendMessage(
            text: text,
            channelId: widget.channelId,
            workspaceId: widget.workspaceId,
            replyToMessageId: widget.replyToMessageId,
          ),
        );
  }

  void _handleClose() {
    // Reset bloc state when closing
    context.read<SendMessageBloc>().add(const ResetSendMessage());
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, conversationState) {
        // Only show the panel if there's exactly one conversation selected
        final shouldShow = conversationState is ConversationLoaded &&
            conversationState.selectedConversationIds.length == 1;

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        return BlocListener<SendMessageBloc, SendMessageState>(
          listener: (context, state) {
            if (state is SendMessageSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message sent successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
              widget.onSuccess?.call();
              _handleClose();
            } else if (state is SendMessageError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: GlassContainer(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reply to Message',
                      style: AppTextStyle.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: _handleClose,
                      size: AppIconButtonSize.small,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Message Input
                AppTextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 5,
                  hint: 'Type your message...',
                ),
                const SizedBox(height: 24),

                // Action Buttons
                BlocBuilder<SendMessageBloc, SendMessageState>(
                  builder: (context, state) {
                    final isLoading = state is SendMessageInProgress;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppOutlinedButton(
                          onPressed: isLoading ? null : _handleClose,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          onPressed: isLoading ? null : _handleSend,
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
