import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
    super.key,
  });

  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No more messages',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoading
            ? const AppProgressIndicator()
            : AppButton(
                onPressed: onLoadMore,
                child: const Text('Load More Messages'),
              ),
      ),
    );
  }
}
