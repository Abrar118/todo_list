import 'package:flutter/material.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
///
/// The world is a ticket rail at the pass: a brushed-steel ground, white
/// ticket surfaces and print-black ink. [accent] is that ink, so chrome and
/// actions carry no colour at all. Colour has one job, heat: [medium] is the
/// heat lamp (a ticket warming) and [overdue] the thermal-printer red (a
/// ticket gone critical). Dark is the same pass after close.
///
/// Two colour families, deliberately kept apart:
///
/// * **Semantic** ([overdue], [medium], [done], [low]) carries meaning —
///   heat, completion, information. Never use these to decorate something.
/// * **Decorative** ([decorative]) carries identity — tags, habits, goals,
///   task card tints. Muted and lighter, so a coral *card* can never be
///   mistaken for a coral *priority flag*.
///
/// Every colour that can end up as text or as a meaningful icon clears
/// WCAG 4.5:1 against [background], [card] and [pressed] in both themes;
/// [accentDim] is non-text only and clears 3:1. `test/design_tokens_test.dart`
/// enforces this.
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

  /// The bright edge along a glass surface. Brighter than [borderStrong]:
  /// it reads as the lit rim of a pane, not as a divider.
  final Color hairline;

  /// Text- and icon-safe accent. Dark enough to sit on paper in light mode,
  /// so it is the only accent allowed to carry a glyph or a label.
  final Color accent;

  /// Non-text accent for borders, tracks and tints. Clears 3:1, not 4.5:1.
  final Color accentDim;

  /// Foreground on [accent]-filled surfaces (filled buttons, checkmarks).
  final Color onAccent;

  /// The signature orange, as a *fill* only — the add button, selected tints.
  /// It is too light to carry white text, which is why it is separate from
  /// [accent]; pair it with [onAccentFill].
  final Color accentFill;

  /// Foreground on [accentFill]. Always the dark glyph.
  final Color onAccentFill;

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
    required this.hairline,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.accentFill,
    required this.onAccentFill,
    required this.overdue,
    required this.medium,
    required this.done,
    required this.low,
    required this.decorative,
  });

  static const dark = AppColors(
    background: Color(0xFF121619),
    elevated: Color(0xFF1A1F23),
    card: Color(0xFF1F252A),
    pressed: Color(0xFF293036),
    textPrimary: Color(0xFFEEF1F3),
    textSecondary: Color(0xFFAAB3BB),
    textMuted: Color(0xFF97A1AA),
    border: Color(0x17FFFFFF), // translucent white
    borderStrong: Color(0x29FFFFFF),
    hairline: Color(0x29FFFFFF),
    accent: Color(0xFFEEF1F3),
    accentDim: Color(0xFF7D8892),
    onAccent: Color(0xFF121619),
    accentFill: Color(0xFFEEF1F3),
    onAccentFill: Color(0xFF121619),
    overdue: Color(0xFFFF7468),
    medium: Color(0xFFF2AE45),
    done: Color(0xFF63D894),
    low: Color(0xFF86BDE0),
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

  /// Service: steel under daylight. Heat colours are darkened so they still
  /// carry text on the steel ground.
  static const light = AppColors(
    background: Color(0xFFDDE2E6),
    elevated: Color(0xFFF3F5F6),
    card: Color(0xFFFFFFFF),
    pressed: Color(0xFFE8ECEE),
    textPrimary: Color(0xFF111417),
    textSecondary: Color(0xFF454E57),
    textMuted: Color(0xFF4F5862),
    border: Color(0x1F0E1A26), // translucent steel
    borderStrong: Color(0x330E1A26),
    hairline: Color(0x330E1A26),
    accent: Color(0xFF111417),
    accentDim: Color(0xFF6A747D),
    onAccent: Color(0xFFFFFFFF),
    accentFill: Color(0xFF111417),
    onAccentFill: Color(0xFFFFFFFF),
    overdue: Color(0xFFAE2A21),
    medium: Color(0xFF7F4C00),
    done: Color(0xFF1C6B41),
    low: Color(0xFF2B5574),
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
    Color? hairline,
    Color? accent,
    Color? accentDim,
    Color? onAccent,
    Color? accentFill,
    Color? onAccentFill,
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
    hairline: hairline ?? this.hairline,
    accent: accent ?? this.accent,
    accentDim: accentDim ?? this.accentDim,
    onAccent: onAccent ?? this.onAccent,
    accentFill: accentFill ?? this.accentFill,
    onAccentFill: onAccentFill ?? this.onAccentFill,
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
      hairline: mix(hairline, other.hairline),
      accent: mix(accent, other.accent),
      accentDim: mix(accentDim, other.accentDim),
      onAccent: mix(onAccent, other.onAccent),
      accentFill: mix(accentFill, other.accentFill),
      onAccentFill: mix(onAccentFill, other.onAccentFill),
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
