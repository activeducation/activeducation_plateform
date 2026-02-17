import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminSnackbar {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message);

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);
}
