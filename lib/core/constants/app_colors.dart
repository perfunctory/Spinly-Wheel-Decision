import 'package:flutter/material.dart';

/// Sector colors for the wheel — 20 colors to cycle through
const sectorColors = [
  Color(0xFFFF6B6B), // Coral red
  Color(0xFF4ECDC4), // Teal
  Color(0xFFFFE66D), // Sunny yellow
  Color(0xFFA8E6CF), // Mint green
  Color(0xFFFF8B94), // Salmon pink
  Color(0xFFB8A9C9), // Lavender
  Color(0xFFFF9F43), // Orange
  Color(0xFF54A0FF), // Blue
  Color(0xFF5F27CD), // Deep purple
  Color(0xFF01A3A4), // Dark teal
  Color(0xFFF368E0), // Magenta
  Color(0xFF2ED573), // Emerald
  Color(0xFFFF6348), // Tomato
  Color(0xFF7BED9F), // Light green
  Color(0xFF70A1FF), // Cornflower blue
  Color(0xFFECCC68), // Gold
  Color(0xFFFF4757), // Watermelon
  Color(0xFF1E90FF), // Dodger blue
  Color(0xFFA29BFE), // Soft purple
  Color(0xFFFD79A8), // Pink
];

/// App theme colors
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  static const Color text = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);

  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF16213E);

  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ED573);

  static const Color wheelCenter = Color(0xFFF8F9FA);
  static const Color wheelBorder = Color(0xFFDFE6E9);

  static const Color pointerColor = Color(0xFF2D3436);
}
