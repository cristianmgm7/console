import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthRequestCard extends StatelessWidget {

  const AuthRequestCard({
    required this.item,
    required this.sessionId,
    super.key,
  });
  
  final AuthRequestItem item;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: Colors.amber[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Authentication Required',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The agent needs authentication to continue.',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (sessionId != null) {
                    // Dispatch auth request detected event to McpAuthBloc
                    context.read<McpAuthBloc>().add(
                      AuthRequestDetected(
                        sessionId: sessionId!,
                        requests: [item.request],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Authenticate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
