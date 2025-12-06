import 'package:carbon_voice_console/core/routing/side_navigation_bar.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {

  const AppShell({
    required this.child, super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed-width left navigation bar
          const SideNavigationBar(),
          // Main content area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
