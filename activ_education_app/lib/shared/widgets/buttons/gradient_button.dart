import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Bouton avec dégradé pour le design professionnel
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool showArrow;
  final bool isSmall;
  final IconData? icon;
  final double? width;
  final bool useSecondaryColor;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.showArrow = true,
    this.isSmall = false,
    this.icon,
    this.width,
    this.useSecondaryColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = useSecondaryColor
        ? AppColors.secondaryGradient
        : AppColors.primaryGradient;

    final shadowColor = useSecondaryColor ? AppColors.secondary : AppColors.primary;

    return Container(
      width: width ?? double.infinity,
      height: isSmall ? 40 : AppSpacing.buttonHeight,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(
          isSmall ? AppSpacing.buttonRadiusFull : AppSpacing.buttonRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            isSmall ? AppSpacing.buttonRadiusFull : AppSpacing.buttonRadius,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? AppSpacing.md : AppSpacing.buttonPaddingHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: isSmall ? 16 : 20),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  text,
                  style: isSmall
                      ? AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)
                      : AppTypography.buttonText,
                ),
                if (showArrow) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: isSmall ? 16 : 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
