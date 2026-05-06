// lib/theme/app_theme.dart
// ─────────────────────────────────────────────
//  SPORT PLUS — DESIGN SYSTEM
//  Single source of truth cho toàn bộ app
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── BRAND COLORS ──────────────────────────────
abstract class AppColors {
  // Primary greens
  static const primary        = Color(0xFF2E7D32);
  static const primaryDark    = Color(0xFF1B5E20);
  static const primaryLight   = Color(0xFF4CAF50);
  static const primaryUltraLight = Color(0xFFE8F5E9);

  // Backgrounds
  static const bgPage         = Color(0xFFF2F5F0);
  static const bgTop          = Color(0xFFF5F7F2);
  static const bgBottom       = Color(0xFFDCEAD8);

  // Card
  static const cardBg         = Colors.white;

  // Text
  static const textDark       = Color(0xFF1A1A1A);
  static const textMid        = Color(0xFF555555);
  static const textLight      = Color(0xFF888888);
  static const textHint       = Color(0xFF9E9E9E);
  static const textLabel      = Color(0xFF666868);

  // Fields
  static const fieldBg        = Color(0xFFEBEDEB);
  static const fieldBorder    = Color(0xFFD8DBD8);
  static const fieldBorderFocus = primary;
  static const fieldBorderError = errorRed;

  // Status
  static const errorRed       = Color(0xFFD32F2F);
  static const successGreen   = primary;
  static const warningOrange  = Color(0xFFFB8C00);
  static const infoBlue       = Color(0xFF1565C0);

  // Booking status badges
  static const badgeBookedBg   = Color(0xFFE8F5E9);
  static const badgeBookedText = primary;
  static const badgeDoneBg     = Color(0xFFF5F5F5);
  static const badgeDoneText   = Color(0xFF757575);
  static const badgeCancelBg   = Color(0xFFFFEBEE);
  static const badgeCancelText = Color(0xFFE53935);

  // Social
  static const socialBg       = Color(0xFFF7F8F7);
  static const socialBorder   = Color(0xFFDDDFDD);
  static const googleRed      = Color(0xFFDB4437);
  static const facebookBlue   = Color(0xFF1877F2);

  // Nav
  static const navUnselected  = Color(0xFF9E9E9E);

  // Misc
  static const divider        = Color(0xFFCCCECC);
  static const dashedLine     = Color(0xFFD4D9D4);
  static const ratingGold     = Color(0xFFFFC107);
  static const logoutBg       = Color(0xFFFFF0EE);
  static const logoutText     = Color(0xFFE53935);
  static const logoutBorder   = Color(0xFFFFCDD2);
}

// ── SPACING ───────────────────────────────────
abstract class AppSpacing {
  static const double pagePadH  = 20.0;
  static const double cardRadius = 16.0;
  static const double fieldRadius = 14.0;
  static const double btnRadius  = 14.0;
  static const double chipRadius = 50.0;
  static const double btnHeight  = 56.0;
}

// ── TEXT STYLES ───────────────────────────────
abstract class AppText {
  static const screenTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const fieldLabel = TextStyle(
    color: AppColors.textLabel,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
  );

  static const hintText = TextStyle(
    color: AppColors.textHint,
    fontSize: 15,
  );

  static const bodyMid = TextStyle(
    color: AppColors.textMid,
    fontSize: 14,
  );

  static const errorStyle = TextStyle(
    color: AppColors.errorRed,
    fontSize: 12,
  );

  static const btnLabel = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
}

// ── SHADOWS ───────────────────────────────────
abstract class AppShadow {
  static const card = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const btn = [
    BoxShadow(
      color: Color(0x402E7D32),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];
}

// ── MATERIAL THEME ────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.green,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bgPage,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.screenTitle,
      iconTheme: IconThemeData(color: AppColors.primary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.navUnselected,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
      ),
      hintStyle: AppText.hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppSpacing.btnHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.btnRadius),
        ),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    ),
  );
}
