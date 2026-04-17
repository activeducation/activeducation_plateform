import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatDivider extends StatelessWidget {
  const StatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.darkBorder,
    );
  }
}
