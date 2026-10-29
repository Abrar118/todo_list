import 'package:flutter/material.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
///
/// The world is a meadow: every root tab opens under a band of fresh grass
/// ([meadowTop], [meadowHill]) that rolls down into a pale green page, with
/// chunky white cards on it. [accentFill] is the vivid leaf green of every
/// primary button, set with a solid darker lip ([accentEdge]) so it looks
/// pressable. The one task that has waited longest sits on a dark-forest
/// [hero] card. Dark is the same meadow at night.
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

  /// The dark-forest card the waiting task sits on, in both themes.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

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

  /// The meadow at night: deep forest ground, cards a clear step lighter.
  static const dark = AppColors(
    background: Color(0xFF0E1912),
    elevated: Color(0xFF16241A),
    card: Color(0xFF1A2B1F),
    pressed: Color(0xFF223727),
    textPrimary: Color(0xFFEDF6E8),
    textSecondary: Color(0xFFB7CBB0),
    textMuted: Color(0xFFA5BA9E),
    border: Color(0x1FE6FFDC), // translucent moonlit green
    borderStrong: Color(0x33E6FFDC),
    accent: Color(0xFF86E04A),
    accentDim: Color(0xFF4D8A37),
    onAccent: Color(0xFF0E1912),
    accentFill: Color(0xFF58CC02),
    onAccentFill: Color(0xFF10270A),
    accentEdge: Color(0xFF3B8A02),
    hero: Color(0xFF215C30),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFC3E8C8),
    heroWarm: Color(0xFFF7BE62),
    heroHot: Color(0xFFFFB8AE),
    meadowTop: Color(0xFF1B3F20),
    meadowHill: Color(0xFF24512A),
    streak: Color(0xFFFF9F1C),
    tintSun: Color(0xFF3A2A12),
    tintLeaf: Color(0xFF1F3A1E),
    tintSky: Color(0xFF172C40),
    overdue: Color(0xFFFF8A7E),
    medium: Color(0xFFF4B04B),
    done: Color(0xFF6ADB8E),
    low: Color(0xFF8CC2EA),
    decorative: [
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
      Color(0xFFCE97B6), // berry,
    ],
  );

  /// The meadow by day. Heat colours are darkened so they still carry text
  /// on the pale green page.
  static const light = AppColors(
    background: Color(0xFFF2F8EA),
    elevated: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    pressed: Color(0xFFE4EFD8),
    textPrimary: Color(0xFF13251A),
    textSecondary: Color(0xFF3B5243),
    textMuted: Color(0xFF4A604F),
    border: Color(0x2413251A), // translucent forest
    borderStrong: Color(0x3813251A),
    accent: Color(0xFF2A750D),
    accentDim: Color(0xFF578F40),
    onAccent: Color(0xFFFFFFFF),
    accentFill: Color(0xFF58CC02),
    onAccentFill: Color(0xFF10270A),
    accentEdge: Color(0xFF46A302),
    hero: Color(0xFF1D4D2B),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFBFE3C4),
    heroWarm: Color(0xFFF4B04B),
    heroHot: Color(0xFFFFB0A6),
    meadowTop: Color(0xFF8BDB4A),
    meadowHill: Color(0xFF6CC72E),
    streak: Color(0xFFFF9600),
    tintSun: Color(0xFFFFEFD2),
    tintLeaf: Color(0xFFDDF4C9),
    tintSky: Color(0xFFDCEBFB),
    overdue: Color(0xFFB3261E),
    medium: Color(0xFF8A4F00),
    done: Color(0xFF21733A),
    low: Color(0xFF2A5C85),
    decorative: [
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
      Color(0xFF6F3456), // berry,
    ],
  );

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

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
