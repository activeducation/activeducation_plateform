import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Anneau de progression de maîtrise (0-1). Bleu de marque, accent ambre
/// quand la maîtrise est élevée. Réutilisable (accueil, page tuteur).
class MasteryRing extends StatelessWidget {
  final double value; // [0,1]
  final double size;
  final String? label;

  const MasteryRing({
    super.key,
    required this.value,
    this.size = 72,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final color = v >= 0.6 ? AppColors.secondary : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value: v, color: color),
            child: Center(
              child: Text(
                '${(v * 100).round()}%',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.24,
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: size + 24,
            child: Text(
              label!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;

  _RingPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 8) / 2;
    final stroke = size.width * 0.11;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.border;

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, track);

    const start = -math.pi / 2; // 12 o'clock
    final sweep = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}
