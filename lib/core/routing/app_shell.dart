import 'package:flutter/material.dart';
import 'presentation/side_navigation_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

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
