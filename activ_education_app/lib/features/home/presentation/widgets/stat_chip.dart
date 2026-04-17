import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color valueColor;

  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                value,
                style: AppTypography.statValueSmall.copyWith(
                  color: valueColor,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}
