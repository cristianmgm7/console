import 'package:flutter/material.dart';

/// Custom painter for audio waveform visualization
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> waveformData;
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final barWidth = size.width / waveformData.length;
    final barGap = barWidth * 0.2;
    final actualBarWidth = barWidth - barGap;
    final midHeight = size.height / 2;

    for (var i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final normalizedValue = waveformData[i].clamp(0.0, 1.0);
      final barHeight = normalizedValue * size.height;

      final isActive = (i / waveformData.length) <= progress;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          midHeight - (barHeight / 2),
          actualBarWidth,
          barHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveformData != waveformData;
  }
}
