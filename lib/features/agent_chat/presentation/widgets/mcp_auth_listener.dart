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
      builder: (dialogContext) => McpAuthenticationDialog(
        request: state.request,
        onAuthenticate: (authCode) {
          // Dispatch event to bloc
          context.read<McpAuthBloc>().add(
                AuthCodeProvided(
                  authorizationCode: authCode,
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
          Navigator.of(dialogContext).pop();
        },
        onCancel: () {
          // Dispatch cancel event to bloc
          context.read<McpAuthBloc>().add(
                AuthCancelled(
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}
