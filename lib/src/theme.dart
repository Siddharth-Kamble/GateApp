import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0B4F8C);
  static const Color secondary = Color(0xFF00B3A6);
  static const Color success = Color(0xFF2BB673);
  static const Color danger = Color(0xFFE74C3C);
  static const Color pending = Color(0xFFF1C40F);
  static const Color bg = Color(0xFFF7FAFF);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black87)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
  );
}
