import 'package:flutter/material.dart';

// Central color definitions — consumed everywhere via Theme.of(context).colorScheme
abstract class AppColors {
  static const background = Color(0xFF0C0E12); // main background
  static const surface = Color(0xFF1A1C22); // card / input surface
  static const gold = Color(0xFFF0B90B); // primary brand / text
  static const goldMuted = Color.fromARGB(
    255,
    135,
    135,
    135,
  ); // subtitle / hint
  static const onGold = Color(0xFF0C0E12); // text on gold buttons
  static const border = Color(0xFF2C2F36); // subtle outlines
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,

      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      primaryContainer: Color(0xFFFFF8E1),
      onPrimaryContainer: Color(0xFF1A1C22),

      secondary: Color(0xFF888888),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEEEEEE),
      onSecondaryContainer: Color(0xFF1A1C22),

      surface: Color(0xFFF0F2F5),
      onSurface: Color(0xFF1A1C22),
      onSurfaceVariant: Color(0xFF555555),
      surfaceContainerHighest: Color(0xFFFFFFFF),

      outline: Color(0xFFDDE1E7),
      outlineVariant: Color(0xFFDDE1E7),

      error: Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),

      inverseSurface: Color(0xFF1A1C22),
      onInverseSurface: Color(0xFFF0F2F5),
      inversePrimary: AppColors.goldMuted,

      scrim: Colors.black,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDE1E7)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.gold),
        prefixIconColor: AppColors.gold,
        counterStyle: const TextStyle(color: Color(0xFF555555)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,

      // Primary — gold for buttons and active elements
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      primaryContainer: AppColors.surface,
      onPrimaryContainer: AppColors.gold,

      // Secondary
      secondary: AppColors.goldMuted,
      onSecondary: AppColors.onGold,
      secondaryContainer: AppColors.surface,
      onSecondaryContainer: AppColors.gold,

      // Surface / background
      surface: AppColors.background,
      onSurface: AppColors.gold, // main text
      onSurfaceVariant: AppColors.goldMuted, // subtitle / hint text
      // Input fill and cards
      surfaceContainerHighest: AppColors.surface,

      // Outlines
      outline: AppColors.border,
      outlineVariant: AppColors.border,

      // Error
      error: Color(0xFFCF6679),
      onError: AppColors.background,
      errorContainer: Color(0xFF8B1A2E),
      onErrorContainer: AppColors.gold,

      // Inverse
      inverseSurface: AppColors.gold,
      onInverseSurface: AppColors.onGold,
      inversePrimary: AppColors.goldMuted,

      scrim: Colors.black,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.gold),
        prefixIconColor: AppColors.gold,
        counterStyle: const TextStyle(color: AppColors.goldMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
    );
  }
}
