import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_outlined_button.dart';
import 'package:carbon_voice_console/core/widgets/interactive/app_text_field.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog to handle MCP tool authentication requests
class McpAuthenticationDialog extends StatefulWidget {
  const McpAuthenticationDialog({
    required this.request,
    required this.onAuthenticate,
    required this.onCancel,
    super.key,
  });

  final AuthenticationRequest request;
  final void Function(String authCode) onAuthenticate;
  final VoidCallback onCancel;

  @override
  State<McpAuthenticationDialog> createState() => _McpAuthenticationDialogState();
}

class _McpAuthenticationDialogState extends State<McpAuthenticationDialog> {
  final _authCodeController = TextEditingController();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _authCodeController.dispose();
    super.dispose();
  }

  void _handleAuthenticate() {
    final code = _authCodeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the authorization code';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    widget.onAuthenticate(code);
  }

  void _copyUrlToClipboard() {
    final url = widget.request.authUri.isNotEmpty 
        ? widget.request.authUri 
        : widget.request.authorizationUrl ?? '';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authorization URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Authentication Required',
              style: AppTextStyle.headlineMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The agent needs to access ${widget.request.provider ?? 'an external service'}. '
              'Please complete the authentication process.',
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Scopes
            if (widget.request.scopes?.isNotEmpty ?? false) ...[
              Text(
                'Required Permissions:',
                style: AppTextStyle.labelMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...widget.request.scopes!.map((scope) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scope,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Authorization URL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 1: Open this URL in your browser',
                          style: AppTextStyle.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: _copyUrlToClipboard,
                        tooltip: 'Copy URL',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.request.authUri.isNotEmpty 
                        ? widget.request.authUri 
                        : widget.request.authorizationUrl ?? 'No URL provided',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auth code input
            Text(
              'Step 2: Paste the authorization code here',
              style: AppTextStyle.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _authCodeController,
              hint: 'Enter authorization code...',
              enabled: !_isAuthenticating,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppOutlinedButton(
          onPressed: _isAuthenticating ? null : widget.onCancel,
          isLoading: false,
          child: const Text('Cancel'),
        ),
        AppButton(
          onPressed: _isAuthenticating ? null : _handleAuthenticate,
          isLoading: _isAuthenticating,
          child: Text(_isAuthenticating ? 'Authenticating...' : 'Authenticate'),
        ),
      ],
    );
  }
}
