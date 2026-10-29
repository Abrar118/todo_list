import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
///
/// The world is a meadow: every root tab opens under a band of fresh grass
/// ([meadowTop], [meadowHill]) that rolls down into a pale green page, with
/// chunky white cards on it. [accentFill] is the vivid leaf green of every
/// primary button, set with a solid darker lip ([accentEdge]) so it looks
/// pressable. The one task that has waited longest sits on a deep [hero]
/// card. Dark is the same meadow at night, matte rather than glowing.
///
/// The hues come from the user's chosen [AppPalette] (green by default);
/// [AppColors.forPalette] derives every role from a few chosen colours.
///
/// Three colour families, deliberately kept apart:
///
/// * **Semantic** ([overdue], [medium], [done], [low]) carries meaning —
///   heat, completion, information. Never use these to decorate something.
///   Lateness is still heat: amber when a task is warming, red when it has
///   gone critical.
/// * **Cheer** ([streak], the three tints) colours the stat tiles and
///   illustrations. Fills only, never text.
/// * **Decorative** ([decorative]) carries identity — tags, habits, goals.
///   Muted, so a coral identity dot is never read as a warning.
///
/// Every colour that can end up as text or as a meaningful icon clears
/// WCAG 4.5:1 against [background], [card] and [pressed] in both themes;
/// [accentDim] is non-text only and clears 3:1. Text on the hero and on the
/// tints is checked too. `test/design_tokens_test.dart` enforces this.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color elevated;
  final Color card;
  final Color pressed;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color border;
  final Color borderStrong;

  /// Text- and icon-safe green: links, text buttons, selected icons.
  final Color accent;

  /// Non-text green for tracks and progress. Clears 3:1, not 4.5:1.
  final Color accentDim;

  /// Foreground on [accent]-filled surfaces.
  final Color onAccent;

  /// The vivid leaf green, as a *fill* only — primary buttons, the add
  /// button, checked boxes. Too light to carry white text; pair it with
  /// [onAccentFill].
  final Color accentFill;

  /// Foreground on [accentFill]. Always the dark glyph.
  final Color onAccentFill;

  /// The solid lip under an [accentFill] button.
  final Color accentEdge;

  /// The deep card the waiting task sits on.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

  /// The Done button on [hero]: [accentFill] unless that would vanish on
  /// the hero (the black palettes), with its own foreground.
  final Color heroAction;
  final Color onHeroAction;

  /// Heat, re-mixed to read on [hero]: warming and critical.
  final Color heroWarm;
  final Color heroHot;

  /// The grass band at the top of every root tab, and the far hill rolling
  /// down out of it.
  final Color meadowTop;
  final Color meadowHill;

  /// Flame orange for streaks. A fill, never text.
  final Color streak;

  /// Stat-tile grounds: sun (streaks), leaf (done), sky (waiting).
  final Color tintSun;
  final Color tintLeaf;
  final Color tintSky;

  final Color overdue;
  final Color medium;
  final Color done;
  final Color low;

  /// The decorative family, in a stable order parallel to `Swatch` — index
  /// n is `Swatch.values[n]`, so never reorder one without the other. Pick
  /// with [decorativeFor] for an auto-assigned colour (tags), or by swatch
  /// index for one the user chose.
  final List<Color> decorative;

  const AppColors({
    required this.background,
    required this.elevated,
    required this.card,
    required this.pressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.accentFill,
    required this.onAccentFill,
    required this.accentEdge,
    required this.heroAction,
    required this.onHeroAction,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroWarm,
    required this.heroHot,
    required this.meadowTop,
    required this.meadowHill,
    required this.streak,
    required this.tintSun,
    required this.tintLeaf,
    required this.tintSky,
    required this.overdue,
    required this.medium,
    required this.done,
    required this.low,
    required this.decorative,
  });

  /// The default palette, green, in each brightness.
  static final dark = AppColors.forPalette(AppPalette.meadow, Brightness.dark);
  static final light = AppColors.forPalette(
    AppPalette.meadow,
    Brightness.light,
  );

  /// Builds a whole palette from a handful of chosen colours (see [_specs]);
  /// every other role is derived, so the eight palettes stay one system.
  ///
  /// Light is a bright page with white cards. Dark is matte: a deep ground
  /// tinted with the palette's hue, and cards a clear, low-saturation step
  /// lighter so they read as solid blocks rather than glowing ones.
  factory AppColors.forPalette(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final (lightSpec, darkSpec) = _specs[palette]!;
    final s = isDark ? darkSpec : lightSpec;
    Color tone(double saturation, double lightness, {double? hue}) =>
        HSLColor.fromAHSL(
          1,
          hue ?? s.hue,
          (saturation * s.tint).clamp(0.0, 1.0),
          lightness,
        ).toColor();
    Color shift(Color c, double by) {
      final hsl = HSLColor.fromColor(c);
      return hsl.withLightness((hsl.lightness + by).clamp(0.0, 1.0)).toColor();
    }

    final fillHsl = HSLColor.fromColor(s.fill);
    // Tints take the palette's hue (not the fill's, which can lean
    // yellow-green and read olive); grey for the black palettes.
    final fillTint = fillHsl.saturation > 0.2 ? 1.0 : 0.0;
    // The deep ink a light fill carries; white for a dark one.
    Color on(Color c) {
      final ink = HSLColor.fromAHSL(
        1,
        HSLColor.fromColor(c).hue,
        0.6 * fillTint,
        0.09,
      ).toColor();
      return _contrast(Colors.white, c) >= _contrast(ink, c)
          ? Colors.white
          : ink;
    }

    final heroAction = s.heroAction ?? s.fill;
    if (!isDark) {
      final background = tone(0.45, 0.95);
      final textPrimary = tone(0.4, 0.11);
      return AppColors(
        background: background,
        elevated: Colors.white,
        card: Colors.white,
        pressed: tone(0.32, 0.905),
        textPrimary: textPrimary,
        textSecondary: tone(0.18, 0.28),
        textMuted: tone(0.14, 0.33),
        border: textPrimary.withAlpha(0x24),
        borderStrong: textPrimary.withAlpha(0x38),
        accent: s.accent,
        accentDim: Color.lerp(s.accent, Colors.white, 0.2)!,
        onAccent: on(s.accent),
        accentFill: s.fill,
        onAccentFill: on(s.fill),
        accentEdge: shift(s.fill, -0.1),
        heroAction: heroAction,
        onHeroAction: on(heroAction),
        hero: s.hero,
        onHero: on(s.hero),
        onHeroMuted: Color.lerp(on(s.hero), s.hero, 0.25)!,
        heroWarm: const Color(0xFFF4B04B),
        heroHot: const Color(0xFFFFB0A6),
        meadowTop: s.band,
        meadowHill: shift(s.band, -0.07),
        streak: const Color(0xFFFF9600),
        tintSun: const Color(0xFFFFEFD2),
        tintLeaf: HSLColor.fromAHSL(1, s.hue, 0.6 * fillTint, 0.9).toColor(),
        tintSky: const Color(0xFFDCEBFB),
        overdue: const Color(0xFFB3261E),
        medium: const Color(0xFF8A4F00),
        done: const Color(0xFF21733A),
        low: const Color(0xFF2A5C85),
        decorative: _decorativeLight,
      );
    }
    final background = tone(0.30, 0.075);
    return AppColors(
      background: background,
      elevated: tone(0.14, 0.13),
      card: tone(0.12, 0.185),
      pressed: tone(0.12, 0.21),
      textPrimary: tone(0.25, 0.94),
      textSecondary: tone(0.14, 0.79),
      textMuted: tone(0.10, 0.72),
      border: tone(0.3, 0.95).withAlpha(0x1F),
      borderStrong: tone(0.3, 0.95).withAlpha(0x38),
      accent: s.accent,
      accentDim: Color.lerp(s.accent, background, 0.25)!,
      onAccent: on(s.accent),
      accentFill: s.fill,
      onAccentFill: on(s.fill),
      accentEdge: shift(s.fill, -0.12),
      heroAction: heroAction,
      onHeroAction: on(heroAction),
      hero: s.hero,
      onHero: on(s.hero),
      onHeroMuted: Color.lerp(on(s.hero), s.hero, 0.22)!,
      heroWarm: const Color(0xFFFFD08A),
      heroHot: const Color(0xFFFFC4BC),
      meadowTop: s.band,
      meadowHill: shift(s.band, 0.06),
      streak: const Color(0xFFFF9F1C),
      tintSun: HSLColor.fromAHSL(1, 32, 0.30, 0.20).toColor(),
      tintLeaf: HSLColor.fromAHSL(1, s.hue, 0.24 * fillTint, 0.20).toColor(),
      tintSky: HSLColor.fromAHSL(1, 212, 0.30, 0.21).toColor(),
      overdue: const Color(0xFFFF8A7E),
      medium: const Color(0xFFF4B04B),
      done: const Color(0xFF6ADB8E),
      low: const Color(0xFF8CC2EA),
      decorative: _decorativeDark,
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  /// The chosen colours per palette, (light, dark). Everything else is
  /// derived in [AppColors.forPalette]; `test/design_tokens_test.dart`
  /// checks every palette's contrast.
  static const _specs = <AppPalette, (_Spec, _Spec)>{
    AppPalette.meadow: (
      _Spec(
        hue: 145,
        fill: Color(0xFF58CC02),
        accent: Color(0xFF2A750D),
        hero: Color(0xFF1D4D2B),
        band: Color(0xFF8BDB4A),
      ),
      _Spec(
        hue: 145,
        fill: Color(0xFF58CC02),
        accent: Color(0xFF86E04A),
        hero: Color(0xFF235A33),
        band: Color(0xFF1E3A27),
      ),
    ),
    AppPalette.lagoon: (
      _Spec(
        hue: 180,
        fill: Color(0xFF14B8A6),
        accent: Color(0xFF0D6B63),
        hero: Color(0xFF134E4A),
        band: Color(0xFF7EE6D6),
      ),
      _Spec(
        hue: 180,
        fill: Color(0xFF2DD4BF),
        accent: Color(0xFF5EEAD4),
        hero: Color(0xFF145A54),
        band: Color(0xFF123B39),
      ),
    ),
    AppPalette.grape: (
      _Spec(
        hue: 275,
        fill: Color(0xFF9333EA),
        accent: Color(0xFF7E22CE),
        hero: Color(0xFF3B0764),
        band: Color(0xFFD8B4FE),
        heroAction: Color(0xFFD8B4FE),
      ),
      _Spec(
        hue: 275,
        fill: Color(0xFFC084FC),
        accent: Color(0xFFD8B4FE),
        hero: Color(0xFF4C1D95),
        band: Color(0xFF2A1A40),
      ),
    ),
    AppPalette.indigo: (
      _Spec(
        hue: 232,
        fill: Color(0xFF4F46E5),
        accent: Color(0xFF4338CA),
        hero: Color(0xFF1E1B4B),
        band: Color(0xFFA5B4FC),
        heroAction: Color(0xFFA5B4FC),
      ),
      _Spec(
        hue: 232,
        fill: Color(0xFF818CF8),
        accent: Color(0xFFA5B4FC),
        hero: Color(0xFF312E81),
        band: Color(0xFF1C1F45),
      ),
    ),
    AppPalette.berry: (
      _Spec(
        hue: 330,
        fill: Color(0xFFF472B6),
        accent: Color(0xFFBE185D),
        hero: Color(0xFF500724),
        band: Color(0xFFFBCFE8),
      ),
      _Spec(
        hue: 330,
        fill: Color(0xFFF472B6),
        accent: Color(0xFFF9A8D4),
        hero: Color(0xFF7A1340),
        band: Color(0xFF3A1729),
      ),
    ),
    AppPalette.sunset: (
      _Spec(
        hue: 28,
        fill: Color(0xFFFF9600),
        accent: Color(0xFF9A4508),
        hero: Color(0xFF7C2D12),
        band: Color(0xFFFDBA74),
      ),
      _Spec(
        hue: 28,
        fill: Color(0xFFFB923C),
        accent: Color(0xFFFDBA74),
        hero: Color(0xFF7C2D12),
        band: Color(0xFF3A2416),
      ),
    ),
    AppPalette.space: (
      _Spec(
        hue: 240,
        tint: 0,
        fill: Color(0xFF1C1C1E),
        accent: Color(0xFF1C1C1E),
        hero: Color(0xFF1C1C1E),
        band: Color(0xFFD1D1D6),
        heroAction: Color(0xFFFFFFFF),
      ),
      _Spec(
        hue: 240,
        tint: 0,
        fill: Color(0xFFF2F2F7),
        accent: Color(0xFFE5E5EA),
        hero: Color(0xFF3A3A3C),
        band: Color(0xFF1C1C1E),
      ),
    ),
    AppPalette.midnight: (
      _Spec(
        hue: 222,
        tint: 0.5,
        fill: Color(0xFF0F172A),
        accent: Color(0xFF1E293B),
        hero: Color(0xFF0F172A),
        band: Color(0xFFCBD5E1),
        heroAction: Color(0xFFBFDBFE),
      ),
      _Spec(
        hue: 222,
        tint: 0.6,
        fill: Color(0xFFBFDBFE),
        accent: Color(0xFFBFDBFE),
        hero: Color(0xFF1E3A5F),
        band: Color(0xFF0F172A),
      ),
    ),
  };

  static const _decorativeDark = [
    Color(0xFFA9C69F), // sage
    Color(0xFF9CBAC9), // mist
    Color(0xFFAC9CC9), // lilac
    Color(0xFFCBAE9A), // clay
    Color(0xFFCBC09A), // sand
    Color(0xFFCB9AA6), // rose
    Color(0xFFB1C89D), // moss
    Color(0xFFADB2B8), // stone
    Color(0xFFD09D95), // brick
    Color(0xFFD5B590), // apricot
    Color(0xFFCDCB98), // ochre
    Color(0xFFBCC99C), // olive
    Color(0xFF9FC6A9), // fern
    Color(0xFF9CC9BE), // seafoam
    Color(0xFF98C7CD), // teal
    Color(0xFF94B5D1), // sky
    Color(0xFF9AA2CB), // denim
    Color(0xFFB49CC9), // iris
    Color(0xFFC5A0C5), // plum
    Color(0xFFCE97B6), // berry
  ];

  static const _decorativeLight = [
    Color(0xFF48673C), // sage
    Color(0xFF395A6A), // mist
    Color(0xFF4B396A), // lilac
    Color(0xFF6C4C37), // clay
    Color(0xFF685D36), // sand
    Color(0xFF6C3745), // rose
    Color(0xFF4E6539), // moss
    Color(0xFF4C5157), // stone
    Color(0xFF713B33), // brick
    Color(0xFF76542D), // apricot
    Color(0xFF646230), // ochre
    Color(0xFF566336), // olive
    Color(0xFF3C6747), // fern
    Color(0xFF37675B), // seafoam
    Color(0xFF36686D), // teal
    Color(0xFF315472), // sky
    Color(0xFF37406C), // denim
    Color(0xFF53396A), // iris
    Color(0xFF653E65), // plum
    Color(0xFF6F3456), // berry
  ];

  /// A stable decorative colour for [seed] (a tag, habit id or goal id).
  /// FNV-1a so that similar names land on different hues — summing code
  /// units would give "work" and "stop" the same colour.
  Color decorativeFor(String seed) {
    var hash = 0x811c9dc5;
    for (final unit in seed.toLowerCase().codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return decorative[hash % decorative.length];
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? elevated,
    Color? card,
    Color? pressed,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? accentDim,
    Color? onAccent,
    Color? accentFill,
    Color? onAccentFill,
    Color? accentEdge,
    Color? heroAction,
    Color? onHeroAction,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? heroWarm,
    Color? heroHot,
    Color? meadowTop,
    Color? meadowHill,
    Color? streak,
    Color? tintSun,
    Color? tintLeaf,
    Color? tintSky,
    Color? overdue,
    Color? medium,
    Color? done,
    Color? low,
    List<Color>? decorative,
  }) => AppColors(
    background: background ?? this.background,
    elevated: elevated ?? this.elevated,
    card: card ?? this.card,
    pressed: pressed ?? this.pressed,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    accent: accent ?? this.accent,
    accentDim: accentDim ?? this.accentDim,
    onAccent: onAccent ?? this.onAccent,
    accentFill: accentFill ?? this.accentFill,
    onAccentFill: onAccentFill ?? this.onAccentFill,
    accentEdge: accentEdge ?? this.accentEdge,
    heroAction: heroAction ?? this.heroAction,
    onHeroAction: onHeroAction ?? this.onHeroAction,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    heroWarm: heroWarm ?? this.heroWarm,
    heroHot: heroHot ?? this.heroHot,
    meadowTop: meadowTop ?? this.meadowTop,
    meadowHill: meadowHill ?? this.meadowHill,
    streak: streak ?? this.streak,
    tintSun: tintSun ?? this.tintSun,
    tintLeaf: tintLeaf ?? this.tintLeaf,
    tintSky: tintSky ?? this.tintSky,
    overdue: overdue ?? this.overdue,
    medium: medium ?? this.medium,
    done: done ?? this.done,
    low: low ?? this.low,
    decorative: decorative ?? this.decorative,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      elevated: mix(elevated, other.elevated),
      card: mix(card, other.card),
      pressed: mix(pressed, other.pressed),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      accent: mix(accent, other.accent),
      accentDim: mix(accentDim, other.accentDim),
      onAccent: mix(onAccent, other.onAccent),
      accentFill: mix(accentFill, other.accentFill),
      onAccentFill: mix(onAccentFill, other.onAccentFill),
      accentEdge: mix(accentEdge, other.accentEdge),
      heroAction: mix(heroAction, other.heroAction),
      onHeroAction: mix(onHeroAction, other.onHeroAction),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
      onHeroMuted: mix(onHeroMuted, other.onHeroMuted),
      heroWarm: mix(heroWarm, other.heroWarm),
      heroHot: mix(heroHot, other.heroHot),
      meadowTop: mix(meadowTop, other.meadowTop),
      meadowHill: mix(meadowHill, other.meadowHill),
      streak: mix(streak, other.streak),
      tintSun: mix(tintSun, other.tintSun),
      tintLeaf: mix(tintLeaf, other.tintLeaf),
      tintSky: mix(tintSky, other.tintSky),
      overdue: mix(overdue, other.overdue),
      medium: mix(medium, other.medium),
      done: mix(done, other.done),
      low: mix(low, other.low),
      decorative: [
        for (var i = 0; i < decorative.length; i++)
          mix(decorative[i], other.decorative[i]),
      ],
    );
  }
}

/// The few colours a palette chooses; [AppColors.forPalette] derives the
/// rest.
class _Spec {
  /// Hue of the neutrals (page, cards, text).
  final double hue;

  /// How strongly the neutrals take [hue]; 0 is pure grey.
  final double tint;
  final Color fill;
  final Color accent;
  final Color hero;
  final Color band;
  final Color? heroAction;

  const _Spec({
    required this.hue,
    this.tint = 1,
    required this.fill,
    required this.accent,
    required this.hero,
    required this.band,
    this.heroAction,
  });
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
