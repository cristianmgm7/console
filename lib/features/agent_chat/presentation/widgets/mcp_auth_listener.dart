import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
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
        // Auth requests are now handled inline in chat conversation
        // Only show success/error feedback
        if (state is McpAuthSuccess) {
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

}
