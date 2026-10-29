import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

/// A continuous-cornered shape with a solid lip along its bottom edge, so a
/// button or card reads as a chunky block you can press. The lip is painted
/// inside the shape, over the fill: give the content [depth] of extra bottom
/// padding so it centres on the face rather than on the whole block.
///
/// Pressed, a button swaps to a shallower lip (see `AppTheme`); the shape
/// lerps, so the block visibly sinks.
class ChunkyBorder extends OutlinedBorder {
  final double radius;
  final Color edge;
  final double depth;

  const ChunkyBorder({
    required this.edge,
    this.radius = 16,
    this.depth = 4,
    super.side,
  });

  RoundedSuperellipseBorder get _base => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );

  @override
  EdgeInsetsGeometry get dimensions => _base.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _base.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _base.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (depth > 0) {
      canvas
        ..save()
        ..clipPath(getOuterPath(rect, textDirection: textDirection))
        ..drawRect(
          Rect.fromLTRB(
            rect.left,
            rect.bottom - depth,
            rect.right,
            rect.bottom,
          ),
          Paint()..color = edge,
        )
        ..restore();
    }
    _base.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  ChunkyBorder copyWith({
    BorderSide? side,
    Color? edge,
    double? radius,
    double? depth,
  }) => ChunkyBorder(
    edge: edge ?? this.edge,
    radius: radius ?? this.radius,
    depth: depth ?? this.depth,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => ChunkyBorder(
    edge: edge,
    radius: radius * t,
    depth: depth * t,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ChunkyBorder
      ? ChunkyBorder(
          edge: Color.lerp(a.edge, edge, t)!,
          radius: lerpDouble(a.radius, radius, t)!,
          depth: lerpDouble(a.depth, depth, t)!,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is ChunkyBorder ? b.lerpFrom(this, t) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is ChunkyBorder &&
      other.edge == edge &&
      other.radius == radius &&
      other.depth == depth &&
      other.side == side;

  @override
  int get hashCode => Object.hash(edge, radius, depth, side);
}
