import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';

/// A frosted pane: blur, vibrancy, a tinted fill and a lit top edge.
///
/// Use this **only where content actually passes behind the surface** —
/// floating chrome, sheets, sticky headers. A blur samples what is behind it,
/// so a pane sitting on the flat scaffold background produces that same flat
/// colour while still paying for a `saveLayer` every frame. For those, use a
/// plain tinted fill instead.
class GlassSurface extends StatelessWidget {
  final Widget child;

  /// Blur radius. Use [AppGlass.chromeSigma] or [AppGlass.panelSigma].
  final double sigma;

  final BorderRadius borderRadius;

  /// Pulled through the glass as a colour cast. Defaults to the card colour.
  final Color? tint;

  /// How strongly [tint] colours the pane.
  final double tintAmount;

  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    required this.sigma,
    required this.borderRadius,
    this.tint,
    this.tintAmount = 0.12,
    this.padding,
    this.boxShadow,
  });

  GlassSurface.chrome({
    super.key,
    required this.child,
    this.tint,
    this.tintAmount = 0.0,
    this.padding,
    this.boxShadow,
  }) : sigma = AppGlass.chromeSigma,
       borderRadius = AppRadii.largeRadius;

  GlassSurface.panel({
    super.key,
    required this.child,
    this.tint,
    this.tintAmount = 0.12,
    this.padding,
    this.boxShadow,
  }) : sigma = AppGlass.panelSigma,
       borderRadius = AppRadii.mediumRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = tint == null
        ? colors.card
        : Color.lerp(colors.card, tint, tintAmount)!;
    final opacity = isDark
        ? AppGlass.fillOpacityDark
        : AppGlass.fillOpacityLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRSuperellipse(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: AppGlass.filter(sigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Lighter at the top edge: a pane catches the light above it.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  base.withValues(alpha: opacity),
                  base.withValues(alpha: opacity * 0.82),
                ],
              ),
            ),
            foregroundDecoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: borderRadius,
                side: BorderSide(
                  color: colors.hairline,
                  width: AppGlass.hairlineWidth,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
