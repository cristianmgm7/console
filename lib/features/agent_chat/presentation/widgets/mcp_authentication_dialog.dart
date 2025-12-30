import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_outlined_button.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
  }

  // Add method to open OAuth URL
  Future<void> _openAuthUrl() async {
    final url = widget.request.authUri.isNotEmpty
        ? widget.request.correctedAuthUri
        : widget.request.authorizationUrl ?? '';

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'No authorization URL provided';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Open URL in system browser
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Failed to open browser. Please try again.';
        });
      }
      // Note: Keep _isAuthenticating = true
      // Dialog will auto-close when McpAuthBloc emits success/error
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Error opening browser: $e';
      });
    }
  }

  void _copyUrlToClipboard() {
    final url = widget.request.authUri.isNotEmpty 
        ? widget.request.correctedAuthUri 
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
          const Icon(
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

            // Primary action button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Click the button below to authenticate',
                    style: AppTextStyle.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    onPressed: _isAuthenticating ? null : _openAuthUrl,
                    isLoading: _isAuthenticating,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isAuthenticating) ...[
                          const Icon(Icons.open_in_browser, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(_isAuthenticating ? 'Waiting for authentication...' : 'Open Browser to Authenticate'),
                      ],
                    ),
                  ),
                  if (_isAuthenticating) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Complete the authentication in your browser.\nThis dialog will close automatically when done.',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fallback: Manual URL copy (collapsed by default)
            ExpansionTile(
              title: Text(
                'Advanced: Manual authentication',
                style: AppTextStyle.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              children: [
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
                              'Authorization URL',
                              style: AppTextStyle.labelSmall.copyWith(
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
                            ? widget.request.correctedAuthUri
                            : widget.request.authorizationUrl ?? 'No URL provided',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
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
      ],
    );
  }
}
