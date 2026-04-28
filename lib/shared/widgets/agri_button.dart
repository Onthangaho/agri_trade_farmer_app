// lib/shared/widgets/agri_button.dart
/// Shared button component with variants and loading animation.

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AgriButton extends StatelessWidget {
  const AgriButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = 'primary',
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final String variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final _VariantStyle style = _resolveStyle(variant);

    final Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: isLoading
          ? SizedBox(
            key: const ValueKey<String>('spinner'),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: style.foreground),
            )
          : Row(
              key: const ValueKey<String>('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(fullWidth ? double.infinity : 0, 52),
      backgroundColor: style.background,
      foregroundColor: style.foreground,
      side: style.border,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: content,
    );
  }

  _VariantStyle _resolveStyle(String variant) {
    switch (variant) {
      case 'outline':
        return const _VariantStyle(
          background: Colors.white,
          foreground: AppColors.navyText,
          border: BorderSide(color: AppColors.navyText),
        );
      case 'danger':
        return const _VariantStyle(
          background: AppColors.errorTerracotta,
          foreground: Colors.white,
          border: BorderSide.none,
        );
      case 'primary':
      default:
        return const _VariantStyle(
          background: AppColors.primaryGreen,
          foreground: Colors.white,
          border: BorderSide.none,
        );
    }
  }
}

class _VariantStyle {
  const _VariantStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final BorderSide border;
}
