import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget that listens to MCP auth state and shows authentication dialogs
class McpAuthListener extends StatelessWidget {
  const McpAuthListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<McpAuthBloc, McpAuthState>(
      listener: (context, state) {
        if (state is McpAuthRequired) {
          _showAuthenticationDialog(context, state);
        } else if (state is McpAuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully authenticated with ${state.provider}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is McpAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: child,
    );
  }

  void _showAuthenticationDialog(BuildContext context, McpAuthRequired state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocListener<McpAuthBloc, McpAuthState>(
        listener: (context, authState) {
          // Auto-close dialog on success or error
          if (authState is McpAuthSuccess || authState is McpAuthError) {
            Navigator.of(dialogContext).pop();

            // Show feedback snackbar
            if (authState is McpAuthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully authenticated with ${authState.provider}'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (authState is McpAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Authentication failed: ${authState.message}'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
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
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    );
  }
}
