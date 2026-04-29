import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final bool? shouldLogout = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.errorTerracotta,
        ),
        title: const Text('Log out of your account?'),
        content: const Text(
          'You will need to sign in again to access your farm dashboard, listings, and profile.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
            ),
            child: const Text('Stay logged in'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorTerracotta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      );
    },
  );
  return shouldLogout ?? false;
}
