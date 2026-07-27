import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Champ de saisie de "tags" (chips ajoutables) — matières préférées, intérêts.
class TagInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> initial;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  const TagInput({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.initial = const [],
    this.suggestions = const [],
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == value.toLowerCase())) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(value);
      _controller.clear();
    });
    widget.onChanged(List.of(_tags));
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(List.of(_tags));
  }

  @override
  Widget build(BuildContext context) {
    final availableSuggestions = widget.suggestions
        .where((s) => !_tags.any((t) => t.toLowerCase() == s.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag, style: AppTypography.labelSmall),
                labelStyle: const TextStyle(color: AppColors.primary),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                deleteIconColor: AppColors.primary,
                onDeleted: () => _remove(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: () => _add(_controller.text),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onSubmitted: _add,
        ),
        if (availableSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: availableSuggestions.take(6).map((s) {
              return ActionChip(
                label: Text('+ $s',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 11)),
                backgroundColor: AppColors.surfaceLow,
                side: const BorderSide(color: AppColors.border),
                onPressed: () => _add(s),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
