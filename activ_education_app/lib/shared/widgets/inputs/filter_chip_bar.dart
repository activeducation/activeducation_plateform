import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Modèle pour un filtre chip
class FilterChipItem {
  final String label;
  final bool isDropdown;
  final List<String>? options;

  const FilterChipItem({
    required this.label,
    this.isDropdown = false,
    this.options,
  });
}

/// Barre de chips de filtrage stylisée
class FilterChipBar extends StatelessWidget {
  final List<FilterChipItem> filters;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const FilterChipBar({
    super.key,
    required this.filters,
    this.selectedIndex = 0,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = index == selectedIndex;

          return Padding(
            padding: EdgeInsets.only(
              right: index < filters.length - 1 ? AppSpacing.sm : 0,
            ),
            child: _FilterChip(
              label: filter.label,
              isSelected: isSelected,
              isDropdown: filter.isDropdown,
              onTap: () => onSelected?.call(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDropdown;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDropdown,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isDropdown) ...[
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
