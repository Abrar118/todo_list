import 'dart:ui';

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

/// Three corner sizes, plus a pill. iOS corners are continuous (squircles),
/// so prefer the `*Shape` getters over [BorderRadius] wherever a widget takes
/// a [ShapeBorder] — a circular-arc corner next to a system sheet is one of
/// the clearest tells that an app is not native.
abstract final class AppRadii {
  /// Chips, meta pills, calendar cells, inline fields.
  static const sm = 10.0;

  /// Cards, task rows, sheets, dialogs, panels.
  static const md = 16.0;

  /// Chrome: the floating nav bar, large surfaces.
  static const lg = 28.0;

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

/// Screen chrome measurements.
abstract final class AppLayout {
  /// Expanded height of a root screen's large title: the toolbar row (56)
  /// plus the title's own line box and its bottom padding.
  ///
  /// `SliverAppBar.large` is not used for this. Its layout is fixed at 152
  /// with a 28pt gap under the title, which no parameter can reach, and it
  /// renders the title twice — once in the collapsed bar and once in the
  /// flexible space. A plain [FlexibleSpaceBar] gives one title widget and a
  /// bottom padding we control.
  static const largeTitleHeight = 104.0;

  /// Collapsed title size (`titleLarge`, 20) × this = the expanded size.
  static const largeTitleScale = 1.6;

  /// Gap under the large title. Also centres the title when collapsed, so it
  /// is half the toolbar's leftover height, not a free choice.
  static const largeTitleGap = AppSpacing.lg;
}

/// The two glass tiers. Glass is only worth its cost where content actually
/// passes behind it — chrome and sheets. A surface sitting on the flat
/// scaffold background has nothing to refract, and a blur of a flat colour is
/// that same flat colour, so use a tinted fill there instead.
abstract final class AppGlass {
  /// Floating chrome: the nav bar, sticky headers.
  static const chromeSigma = 32.0;

  /// Panels and sheets.
  static const panelSigma = 16.0;

  static const hairlineWidth = 1.0;

  /// Opacity of the glass fill itself, per theme. Light glass has to be
  /// *lighter* than its backdrop to read as glass at all.
  static const fillOpacityDark = 0.72;
  static const fillOpacityLight = 0.84;

  /// Saturation boost applied under the blur. iOS vibrancy does this: the
  /// colour pulled through frosted glass is more saturated than the source,
  /// which is what stops a blur from looking like grey fog.
  static const saturation = <double>[
    1.52992, -0.47216, -0.05776, 0, 0, //
    -0.14008, 1.19784, -0.05776, 0, 0, //
    -0.14008, -0.47216, 1.61224, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  static ImageFilter filter(double sigma) => ImageFilter.compose(
    outer: const ColorFilter.matrix(saturation),
    inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  );

  static ImageFilter get chromeFilter => filter(chromeSigma);
  static ImageFilter get panelFilter => filter(panelSigma);
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
