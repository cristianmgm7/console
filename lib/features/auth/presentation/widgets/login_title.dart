import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/carbon-voice-logo.png',
      fit: BoxFit.contain,
      height: 60,
    );
  }
}
