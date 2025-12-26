import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class ChatInputPanel extends StatefulWidget {
  const ChatInputPanel({super.key});

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // TODO: Send message via BLoC
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _controller,
              focusNode: _focusNode,
              hint: 'Ask the agent anything...',
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 12),

          AppButton(
            onPressed: _sendMessage,
            child: Icon(AppIcons.share, size: 20), // TODO: Use paper plane icon if available
          ),
        ],
      ),
    );
  }
}
