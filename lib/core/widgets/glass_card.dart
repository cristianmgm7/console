import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {

  const GlassCard({super.key, required this.child, this.opacity = 0.5});
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24), // The heavy roundness
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The blur strength
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity), // Glass opacity
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2), // Subtle frost border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
