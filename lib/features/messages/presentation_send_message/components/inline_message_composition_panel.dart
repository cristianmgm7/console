import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_icon_button.dart';
import 'package:carbon_voice_console/core/widgets/containers/glass_container.dart';
import 'package:carbon_voice_console/core/widgets/interactive/app_text_field.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InlineMessageCompositionPanel extends StatefulWidget {
  const InlineMessageCompositionPanel({
    required this.workspaceId,
    required this.channelId,
    this.replyToMessageId,
    this.onClose,
    this.onSuccess,
    this.onCancelReply,
    super.key,
  });

  final String workspaceId;
  final String channelId;
  final String? replyToMessageId;
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancelReply;

  @override
  State<InlineMessageCompositionPanel> createState() => _InlineMessageCompositionPanelState();
}

class _InlineMessageCompositionPanelState extends State<InlineMessageCompositionPanel> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Listen to text changes to update button state
    _messageController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(InlineMessageCompositionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear text when switching to reply to a different message or canceling reply
    if (oldWidget.replyToMessageId != widget.replyToMessageId) {
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
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
        width: 550,
        padding: const EdgeInsets.all(16),
        opacity: 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Message Header
            if (widget.replyToMessageId != null)
              BlocSelector<MessageBloc, MessageState, String?>(
                selector: (state) {
                  if (state is MessageLoaded) {
                    final messages = state.messages.where((m) => m.id == widget.replyToMessageId);
                    if (messages.isNotEmpty) {
                      final message = messages.first;
                      // Get preview of the message text (first 50 characters)
                      final textPreview = message.textModels.isNotEmpty
                          ? message.textModels.first.text
                          : 'Voice message';
                      return textPreview.length > 50
                          ? '${textPreview.substring(0, 50)}...'
                          : textPreview;
                    } else {
                      return 'Message not found';
                    }
                  }
                  return null;
                },
                builder: (context, messagePreview) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.reply,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            messagePreview ?? 'Loading...',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: widget.onCancelReply,
                          icon: Icon(
                            AppIcons.close,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          tooltip: 'Cancel reply',
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Conversation Name Header
            BlocSelector<ConversationBloc, ConversationState, String?>(
              selector: (state) {
                if (state is ConversationLoaded) {
                  // Find conversation by channelId (which could be channelGuid or id)
                  try {
                    final conversation = state.conversations.firstWhere(
                      (c) => c.channelGuid == widget.channelId ||
                             c.id == widget.channelId,
                    );
                    return conversation.name;
                  } on Exception {
                    return 'Unknown Conversation';
                  }
                }
                return null;
              },
              builder: (context, conversationName) {
                if (conversationName == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.message,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sending to: $conversationName',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Message Input Row
            Row(
              children: [
                // Message Input - takes most of the space
                Expanded(
                  child: AppTextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: null, // Allow automatic expansion
                    minLines: 1, // Start with single line
                    hint: 'Type your message...',
                  ),
                ),
                const SizedBox(width: 12),

                // Single Action Button
                BlocBuilder<SendMessageBloc, SendMessageState>(
                  builder: (context, state) {
                    final isLoading = state is SendMessageInProgress;
                    final hasText = _messageController.text.trim().isNotEmpty;

                    return AppIconButton(
                      icon: hasText ? AppIcons.chevronUp : AppIcons.close,
                      onPressed: isLoading
                          ? null
                          : hasText
                              ? _handleSend
                              : _handleClose,
                      tooltip: hasText ? 'Send message' : 'Cancel',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
