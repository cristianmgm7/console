import 'package:flutter/material.dart';

class AppBorders {
  static const double radiustiny = 8;
  static const double radiusSmall = 12;
  static const double radiusCard = 24;
  static const double radiusButton = 50;

  static BorderRadius get small => BorderRadius.circular(radiusSmall);
  static BorderRadius get card => BorderRadius.circular(radiusCard);
  static BorderRadius get button => BorderRadius.circular(radiusButton);
}
