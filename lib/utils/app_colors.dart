// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF6A1B9A);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color accent = Color(0xFFE040FB);
  
  // Couleurs de fond
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Couleurs de gradient
  static const List<Color> primaryGradient = [primary, secondary];
}