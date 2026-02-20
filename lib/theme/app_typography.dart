import 'package:flutter/material.dart';

// === COLORS ===
class AppColors {
  AppColors._();

  static const textPrimary = Color(0xFF282828); // 900 - headings
  static const textSecondary = Color(0xFF545454); // 700 - supporting text
  static const textTertiary = Color(0xFF676767); // 600 - nav, descriptions
  static const textBrand = Color(0xFF282828); // 900 - brand/tags

  static const textQuaternary = Color(0xFF858585); // 500 - subtle labels

  // Button colors
  static const accent = Color(0xFF282828); // primary button bg/border
  static const borderSecondary = Color(0xFFDDDDDD); // secondary button border

  // Background colors
  static const bgSecondary = Color(0xFFF7F7F7); // icon containers
  static const bgTertiary = Color(0xFFF0F0F0); // progress bar track
}

// === TEXT STYLES ===
class AppTextStyles {
  AppTextStyles._();

  // Display sm/Semibold - page titles ("Edit Listing")
  static const displaySm = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 38 / 30,
    color: AppColors.textPrimary,
  );

  // Display xs/Semibold - card headings ("Basic information")
  static const displayXs = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.textPrimary,
  );

  // Text lg/Semibold - section sub-headings ("Essentials")
  static const textLgSemibold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    color: AppColors.textPrimary,
  );

  // Text md/Semibold - nav items, toggle labels ("Smoking allowed")
  static const textMdSemibold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  // Text md/Medium - location text ("Marrakech, Morocco")
  static const textMdMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    color: AppColors.textTertiary,
  );

  // Text md/Regular - supporting/description text
  static const textMdRegular = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textSecondary,
  );

  // Text sm/Semibold - feature tags in brand color ("Wifi")
  static const textSmSemibold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textBrand,
  );

  // Text sm/Medium - input labels, meta info, small descriptions
  static const textSmMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.textSecondary,
  );
}
