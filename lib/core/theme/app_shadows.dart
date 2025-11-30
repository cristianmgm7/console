import 'package:flutter/material.dart';

class AppShadows {
  static const BoxShadow diffused = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 24,
    offset: Offset(0, 4),
  );
  
  static BoxShadow colored(Color color) => BoxShadow(
    color: color.withOpacity(0.4),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
}
