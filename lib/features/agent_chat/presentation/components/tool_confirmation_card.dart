import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:flutter/material.dart';

class ToolConfirmationCard extends StatelessWidget {

  const ToolConfirmationCard({
    required this.item,
    super.key,
  });

  
  final ToolConfirmationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.warning_amber_rounded, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmation Required',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The agent wants to run: ${item.functionName}',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.args.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Args: ${item.args}',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement deny logic
                      },
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                         // TODO: Implement approve logic
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
