import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme/app_typography.dart';

void main() {
  runApp(const VideoCompressorApp());
}

class VideoCompressorApp extends StatelessWidget {
  const VideoCompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Compressor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          primary: AppColors.accent,
        ),
        useMaterial3: true,
        fontFamily: 'OverusedGrotesk',
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderSecondary),
          ),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSecondary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearTrackColor: AppColors.bgTertiary,
          color: AppColors.accent,
          linearMinHeight: 8,
        ),
        textTheme: const TextTheme(
          headlineLarge: AppTextStyles.displaySm,
          headlineMedium: AppTextStyles.displayXs,
          titleLarge: AppTextStyles.textLgSemibold,
          titleMedium: AppTextStyles.textMdSemibold,
          titleSmall: AppTextStyles.textMdMedium,
          bodyLarge: AppTextStyles.textMdRegular,
          bodyMedium: AppTextStyles.textSmMedium,
          bodySmall: AppTextStyles.textSmMedium,
          labelLarge: AppTextStyles.textMdSemibold,
          labelMedium: AppTextStyles.textSmSemibold,
          labelSmall: AppTextStyles.textSmMedium,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTextStyles.textLgSemibold,
          centerTitle: true,
          shape: Border(
            bottom: BorderSide(color: AppColors.borderSecondary),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.textMdSemibold.copyWith(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            textStyle: AppTextStyles.textMdSemibold.copyWith(color: AppColors.textSecondary),
            side: const BorderSide(color: AppColors.borderSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            textStyle: AppTextStyles.textMdSemibold.copyWith(color: AppColors.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}
