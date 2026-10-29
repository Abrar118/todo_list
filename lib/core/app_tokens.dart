import 'package:flutter/widgets.dart';

/// The 4/8 spacing rhythm. Every gap, pad and inset comes from here, so that
/// sibling screens line up without anyone measuring.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Three corner sizes, plus a pill. Generous on purpose: the meadow's cards
/// and buttons are chunky and soft, like toy blocks. iOS corners are
/// continuous (squircles), so prefer the `*Shape` getters over
/// [BorderRadius] wherever a widget takes a [ShapeBorder].
abstract final class AppRadii {
  /// Chips, meta pills, calendar cells, inline fields.
  static const sm = 10.0;

  /// Buttons, task cards, stat tiles, panels.
  static const md = 16.0;

  /// The hero card, the calendar month, the floating tab bar, sheet tops.
  static const lg = 24.0;

  static const pill = 999.0;

  static BorderRadius get smallRadius => BorderRadius.circular(sm);
  static BorderRadius get mediumRadius => BorderRadius.circular(md);
  static BorderRadius get largeRadius => BorderRadius.circular(lg);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);

  static RoundedSuperellipseBorder shape(double radius, {BorderSide? side}) =>
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );

  static RoundedSuperellipseBorder get smallShape => shape(sm);
  static RoundedSuperellipseBorder get mediumShape => shape(md);
  static RoundedSuperellipseBorder get largeShape => shape(lg);

  /// Sheets: continuous corners on the top edge only.
  static RoundedSuperellipseBorder get sheetShape =>
      const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(lg)),
      );
}

/// The type scale, loosely iOS's ramp. Nine sizes, no half-points: a
/// half-point size is per-widget hand-tuning, and the sum of it is what reads
/// as unpolished.
///
/// [figure] and [figureLarge] exist only for the timer and streak numerals,
/// which are display figures rather than text.
abstract final class AppTypography {
  static const caption = 11.0;
  static const footnote = 13.0;
  static const body = 15.0;
  static const callout = 17.0;
  static const title3 = 20.0;
  static const title1 = 28.0;
  static const display = 34.0;
  static const figure = 56.0;
  static const figureLarge = 112.0;

  /// Tightening that stays readable at each size. Large type needs negative
  /// tracking to avoid looking loose; small type needs none.
  static double trackingFor(double size) => switch (size) {
    >= figure => -2.0,
    >= title1 => -0.8,
    >= title3 => -0.4,
    >= callout => -0.2,
    _ => 0.0,
  };
}

/// Motion durations. Distance and complexity pick the duration; everything
/// honours `MediaQuery.disableAnimationsOf`.
abstract final class AppMotion {
  /// State flips: selection, checkmarks, chips.
  static const quick = Duration(milliseconds: 140);

  /// Local movement: expanding a panel, a nav indicator.
  static const standard = Duration(milliseconds: 240);

  /// Full-surface transitions.
  static const slow = Duration(milliseconds: 360);

  static const curve = Curves.easeOutCubic;

  /// Exits read better slightly faster than entrances.
  static const exitCurve = Curves.easeInCubic;
}
