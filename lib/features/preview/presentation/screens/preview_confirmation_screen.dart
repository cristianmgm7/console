import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_share_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen showing successful preview publication (demo version)
class PreviewConfirmationScreen extends StatelessWidget {
  const PreviewConfirmationScreen({
    required this.mockPreviewUrl,
    super.key,
  });

  final String mockPreviewUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Published (Demo)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success message
              Center(
                child: Text(
                  'Preview Published Successfully!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This is a UI demo. In production, your conversation preview would be live and ready to share.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Share panel
              PreviewSharePanel(publicUrl: mockPreviewUrl),
              const SizedBox(height: 32),

              // Back to dashboard button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Dashboard'),
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
