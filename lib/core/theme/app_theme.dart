// lib/core/theme/app_theme.dart
/// ThemeData configuration for AgriTrade light and dark modes.

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  static const String primaryFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Nunito Sans';

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
      secondary: AppColors.accentAmber,
      onSecondary: AppColors.navyText,
      error: AppColors.errorTerracotta,
      onError: Colors.white,
      surface: isLight ? AppColors.backgroundCream : const Color(0xFF121C16),
      onSurface: isLight ? AppColors.navyText : Colors.white,
      tertiary: AppColors.primaryGreenLight,
      onTertiary: Colors.white,
      outline: isLight ? const Color(0xFFD7E0D7) : const Color(0xFF415047),
      shadow: Colors.black,
      inverseSurface: isLight ? AppColors.navyText : AppColors.backgroundCream,
      onInverseSurface: isLight ? Colors.white : AppColors.navyText,
      surfaceTint: AppColors.primaryGreen,
      scrim: Colors.black,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: _headlineStyle(32, FontWeight.w700, colorScheme.onSurface),
      displayMedium: _headlineStyle(28, FontWeight.w700, colorScheme.onSurface),
      displaySmall: _headlineStyle(24, FontWeight.w700, colorScheme.onSurface),
      headlineLarge: _headlineStyle(22, FontWeight.w600, colorScheme.onSurface),
      headlineMedium: _headlineStyle(20, FontWeight.w600, colorScheme.onSurface),
      headlineSmall: _headlineStyle(18, FontWeight.w600, colorScheme.onSurface),
      titleLarge: _bodyStyle(18, FontWeight.w600, colorScheme.onSurface),
      titleMedium: _bodyStyle(16, FontWeight.w600, colorScheme.onSurface),
      titleSmall: _bodyStyle(14, FontWeight.w600, colorScheme.onSurface),
      bodyLarge: _bodyStyle(18, FontWeight.w400, colorScheme.onSurface),
      bodyMedium: _bodyStyle(16, FontWeight.w400, colorScheme.onSurface),
      bodySmall: _bodyStyle(13, FontWeight.w400, AppColors.mutedText),
      labelLarge: _bodyStyle(16, FontWeight.w600, colorScheme.onSurface),
      labelMedium: _bodyStyle(14, FontWeight.w600, colorScheme.onSurface),
      labelSmall: _bodyStyle(13, FontWeight.w600, AppColors.mutedText),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: bodyFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight ? AppColors.backgroundCream : const Color(0xFF0F1713),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.primaryGreen : AppColors.primaryGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: _headlineStyle(20, FontWeight.w600, Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF121C16),
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: _bodyStyle(13, FontWeight.w600, colorScheme.primary),
        unselectedLabelStyle: _bodyStyle(13, FontWeight.w400, AppColors.mutedText),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.navyText,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppSizes.radiusLg)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentAmber,
        foregroundColor: AppColors.navyText,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.tapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          textStyle: _bodyStyle(16, FontWeight.w600, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          minimumSize: const Size.fromHeight(AppSizes.tapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          textStyle: _bodyStyle(16, FontWeight.w600, AppColors.primaryGreen),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surfaceMist : const Color(0xFF18231D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFD7E0D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorTerracotta),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorTerracotta, width: 1.5),
        ),
        hintStyle: _bodyStyle(16, FontWeight.w400, AppColors.mutedText),
        labelStyle: _bodyStyle(16, FontWeight.w500, AppColors.mutedText),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : const Color(0xFF18231D),
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.surfaceMist : const Color(0xFF18231D),
        selectedColor: AppColors.primaryGreenLight,
        secondarySelectedColor: AppColors.primaryGreenLight,
        disabledColor: AppColors.mutedText.withValues(alpha: 0.2),
        labelStyle: _bodyStyle(14, FontWeight.w600, colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
      ),
      textTheme: textTheme,
      dividerColor: isLight ? const Color(0xFFD7E0D7) : const Color(0xFF415047),
    );
  }

  static TextStyle _headlineStyle(double size, FontWeight weight, Color color) {
    return TextStyle(
      fontFamily: primaryFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle _bodyStyle(double size, FontWeight weight, Color color) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }
}
