import 'package:flutter/material.dart';
import 'package:plainscan/core/constants/app_colors.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.background,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: AppColors.text),
    bodyMedium: TextStyle(color: AppColors.secondaryText),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.text,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.secondaryText,
  ),
);
