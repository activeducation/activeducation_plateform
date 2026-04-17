import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HomeIconButton extends StatelessWidget {
  final IconData icon;
  final bool badgeActive;
  final VoidCallback onTap;

  const HomeIconButton({
    super.key,
    required this.icon,
    this.badgeActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 19),
            color: AppColors.darkTextSecondary,
            onPressed: onTap,
          ),
        ),
        if (badgeActive)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBg, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
