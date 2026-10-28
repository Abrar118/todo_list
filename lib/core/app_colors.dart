import 'package:flutter/material.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
/// Dark is a blue-slate base with a vivid orange accent; light is its clean
/// paper equivalent.
///
/// Two colour families, deliberately kept apart:
///
/// * **Semantic** ([accent], [overdue], [medium], [done], [low]) carries
///   meaning — priority, lateness, completion. Saturated and assertive.
///   Never use these to decorate something.
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
    background: Color(0xFF151A21),
    elevated: Color(0xFF1C222B),
    card: Color(0xFF222934),
    pressed: Color(0xFF2B3340),
    textPrimary: Color(0xFFF3F6FA),
    textSecondary: Color(0xFFA8B2C0),
    textMuted: Color(0xFF94A0B0),
    border: Color(0x14FFFFFF), // translucent white
    borderStrong: Color(0x24FFFFFF),
    hairline: Color(0x2EFFFFFF),
    accent: Color(0xFFFF9452),
    accentDim: Color(0xFFE8792C),
    onAccent: Color(0xFF231202),
    accentFill: Color(0xFFF97316),
    onAccentFill: Color(0xFF231202),
    overdue: Color(0xFFFF6F6F),
    medium: Color(0xFFF7C85A),
    done: Color(0xFF63D894),
    low: Color(0xFF5FCBF5),
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

  /// Status colours are darkened for contrast on paper, and [accent] becomes
  /// a deep burnt orange — the bright orange cannot carry white text at
  /// 4.5:1, so it moves to [accentFill].
  static const light = AppColors(
    background: Color(0xFFEEF1F6),
    elevated: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    pressed: Color(0xFFDCE2EB),
    textPrimary: Color(0xFF141922),
    textSecondary: Color(0xFF505B6B),
    textMuted: Color(0xFF55606F),
    border: Color(0x16000000), // translucent black
    borderStrong: Color(0x26000000),
    hairline: Color(0x66FFFFFF),
    accent: Color(0xFFA04A05),
    accentDim: Color(0xFF853D04),
    onAccent: Color(0xFFFFFFFF),
    accentFill: Color(0xFFF97316),
    onAccentFill: Color(0xFF231202),
    overdue: Color(0xFFB32F2F),
    medium: Color(0xFF7A5410),
    done: Color(0xFF1C6B41),
    low: Color(0xFF0E5C79),
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
