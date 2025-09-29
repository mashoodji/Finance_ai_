// lib/presentation/screens/dashboard/chart_utils.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartColors {
  static const List<Color> pieColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];

  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFF44336);
  static const Color gridColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF424242);
}

class ChartStyles {
  static TextStyle get chartTitle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static TextStyle get chartLabel => const TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );
}