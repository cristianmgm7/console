import 'package:carbon_voice_console/features/message_download/presentation/widgets/circular_download_progress_widget.dart';
import 'package:flutter/material.dart';

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 100,
      right: 24,
      child: CircularDownloadProgressWidget(),
    );
  }
}
