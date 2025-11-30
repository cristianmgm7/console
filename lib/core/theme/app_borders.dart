import 'package:flutter/material.dart';

class AppBorders {
  static const double radiusSmall = 12.0;
  static const double radiusCard = 24.0;
  static const double radiusButton = 50.0;

  static BorderRadius get small => BorderRadius.circular(radiusSmall);
  static BorderRadius get card => BorderRadius.circular(radiusCard);
  static BorderRadius get button => BorderRadius.circular(radiusButton);
}
