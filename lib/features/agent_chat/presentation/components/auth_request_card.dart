import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthRequestCard extends StatefulWidget {
  const AuthRequestCard({
    required this.item,
    required this.sessionId,
    super.key,
  });

  final AuthRequestItem item;
  final String? sessionId;

  @override
  State<AuthRequestCard> createState() => _AuthRequestCardState();
}

class _AuthRequestCardState extends State<AuthRequestCard> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<McpAuthBloc, McpAuthState>(
      listener: (context, state) {
        if (state is McpAuthRequired && state.sessionId == widget.sessionId) {
          // Show authentication dialog when auth is required for this session
          _showAuthenticationDialog(context, state);
        } else if (state is McpAuthSuccess && state.sessionId == widget.sessionId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully authenticated with ${state.provider}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is McpAuthError && state.sessionId == widget.sessionId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Padding(
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
                    if (widget.sessionId != null) {
                      // Dispatch auth request detected event to McpAuthBloc
                      context.read<McpAuthBloc>().add(
                        AuthRequestDetected(
                          sessionId: widget.sessionId!,
                          requests: [widget.item.request],
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
      ),
    );
  }

  void _showAuthenticationDialog(BuildContext context, McpAuthRequired state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocListener<McpAuthBloc, McpAuthState>(
        listener: (context, authState) {
          // Auto-close dialog on success or error
          // Close if it's for this session, or if sessionId is empty (error from deep link)
          if (authState is McpAuthSuccess) {
            if (authState.sessionId == state.sessionId || authState.sessionId.isEmpty) {
              Navigator.of(dialogContext).pop();
            }
          } else if (authState is McpAuthError) {
            // Always close on error - either it's for this session or a general error
            Navigator.of(dialogContext).pop();
          }
        },
        child: McpAuthenticationDialog(
          request: state.request,
          onAuthenticate: (authCode) {
            // This is now only used for manual code entry (fallback)
            context.read<McpAuthBloc>().add(
              AuthCodeProvided(
                authorizationCode: authCode,
                request: state.request,
                sessionId: state.sessionId,
              ),
            );
          },
          onCancel: () {
            context.read<McpAuthBloc>().add(
              AuthCancelled(
                request: state.request,
                sessionId: state.sessionId,
              ),
            );
          },
        ),
      ),
    );
  }
}
