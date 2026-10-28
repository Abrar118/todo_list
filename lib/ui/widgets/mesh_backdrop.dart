import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// A quiet, fixed colour field behind the whole app.
///
/// Glass only reads as glass when there is something behind it to refract. On
/// a flat scaffold colour a blur returns that same colour, so the nav bar and
/// sheets looked like plain translucent rectangles no matter how they were
/// tuned. Three very low-saturation fields fix that at the cost of one paint.
///
/// Deliberately static and very subtle: this is a backdrop, not decoration.
/// It draws from [AppColors.decorative] so it follows the theme, and it never
/// animates — motion here would pull attention away from the task list.
class MeshBackdrop extends StatelessWidget {
  final Widget child;

  const MeshBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On paper the decorative family is dark, so the same strength that
    // reads as a faint glow on black reads as dirt on cream. Much lighter.
    final strength = isDark ? 0.22 : 0.06;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MeshPainter(
                  background: colors.background,
                  fields: [
                    (colors.decorative[1], const Alignment(-0.8, -0.9), 1.1),
                    (colors.decorative[0], const Alignment(1.0, -0.2), 0.9),
                    (colors.decorative[2], const Alignment(-0.4, 0.95), 1.0),
                  ],
                  strength: strength,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color background;
  final List<(Color, Alignment, double)> fields;
  final double strength;

  const _MeshPainter({
    required this.background,
    required this.fields,
    required this.strength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final diagonal = size.shortestSide;
    for (final (color, alignment, scale) in fields) {
      final center = alignment.alongSize(size);
      final radius = diagonal * scale;
      // Blend toward the background at the rim so the fields have no edge.
      final tinted = Color.lerp(background, color, strength)!;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [tinted, background.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.strength != strength ||
      oldDelegate.fields != fields;
}
