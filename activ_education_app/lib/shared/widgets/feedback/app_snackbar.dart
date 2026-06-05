import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Helper centralise pour les notifications (SnackBar) de l'app etudiant.
///
/// Remplace les blocs ScaffoldMessenger.showSnackBar dupliques dans les pages.
/// Style coherent : flottant, coins arrondis, icone selon le type.
class AppSnackbar {
  AppSnackbar._();

  static void _show(
    BuildContext context,
    String message, {
    required Color color,
    required IconData icon,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          action: action,
        ),
      );
  }

  static void success(BuildContext context, String message) => _show(
        context,
        message,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message,
        color: AppColors.error,
        icon: Icons.error_outline_rounded,
      );

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(
        context,
        message,
        color: AppColors.primary,
        icon: Icons.info_outline_rounded,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      );
}
