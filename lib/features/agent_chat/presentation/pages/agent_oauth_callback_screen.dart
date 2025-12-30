import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen that handles OAuth callbacks for agent authentication (MCP tools).
///
/// This is separate from the user login OAuth callback and specifically
/// handles authentication for MCP tools like GitHub, Atlassian, etc.
///
/// Flow:
/// 1. User completes OAuth in browser
/// 2. Browser redirects to carbonvoice://agent-auth/callback?code=XXX&state=YYY
/// 3. This screen extracts the code and state
/// 4. Sends AuthCodeProvidedFromDeepLink event to McpAuthBloc
/// 5. Shows loading state while authentication completes
/// 6. Auto-closes when done
class AgentOAuthCallbackScreen extends StatefulWidget {
  const AgentOAuthCallbackScreen({
    required this.callbackUri,
    super.key,
  });

  final Uri callbackUri;

  @override
  State<AgentOAuthCallbackScreen> createState() => _AgentOAuthCallbackScreenState();
}

class _AgentOAuthCallbackScreenState extends State<AgentOAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  void _handleCallback() {
    final code = widget.callbackUri.queryParameters['code'];
    final state = widget.callbackUri.queryParameters['state'];
    final error = widget.callbackUri.queryParameters['error'];
    final errorDescription = widget.callbackUri.queryParameters['error_description'];

    if (error != null) {
      // OAuth error - show error and close after delay
      _showErrorAndClose(error, errorDescription);
      return;
    }

    if (code == null || state == null) {
      _showErrorAndClose('invalid_callback', 'Missing authorization code or state');
      return;
    }

    // Success - send code to McpAuthBloc
    // The bloc will handle the code exchange and credential sending
    context.read<McpAuthBloc>().add(
      AuthCodeProvidedFromDeepLink(
        authorizationCode: code,
        state: state,
      ),
    );
  }

  void _showErrorAndClose(String error, String? description) {
    // Show error snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: $error${description != null ? ' - $description' : ''}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Close this screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientPurple,
              AppColors.gradientPink,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Completing authentication...',
                style: AppTextStyle.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This window will close automatically',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
