import 'package:flutter/material.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
/// Dark is the black-first wellness look; light is its clean paper equivalent.
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

  /// The signature lime, as a *fill* only — the add button, selected tints.
  /// In light mode it is too light to carry white text, which is why it is
  /// separate from [accent]; pair it with [onAccentFill].
  final Color accentFill;

  /// Foreground on [accentFill]. Always the dark glyph.
  final Color onAccentFill;

  final Color overdue;
  final Color medium;
  final Color done;
  final Color low;

  /// The decorative family, in a stable order. Pick with [decorativeFor] so
  /// the same tag or habit keeps its colour across launches.
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
    background: Color(0xFF090B09),
    elevated: Color(0xFF101310),
    card: Color(0xFF171A17),
    pressed: Color(0xFF20251F),
    textPrimary: Color(0xFFF6F8F1),
    textSecondary: Color(0xFFA8ADA1),
    textMuted: Color(0xFF8E958A),
    border: Color(0x14FFFFFF), // translucent white
    borderStrong: Color(0x24FFFFFF),
    hairline: Color(0x2EFFFFFF),
    accent: Color(0xFFB7F23E),
    accentDim: Color(0xFF8FC72C),
    onAccent: Color(0xFF10150A),
    accentFill: Color(0xFFB7F23E),
    onAccentFill: Color(0xFF10150A),
    overdue: Color(0xFFD76B5F),
    medium: Color(0xFFEDB95C),
    done: Color(0xFF9ED83A),
    low: Color(0xFF76D7D0),
    decorative: [
      Color(0xFFA8C49A), // sage
      Color(0xFF9FBCC9), // mist
      Color(0xFFB4A8D0), // lilac
      Color(0xFFC9A890), // clay
      Color(0xFFCFC39A), // sand
      Color(0xFFCFA3AE), // rose
      Color(0xFFA9BE8C), // moss
      Color(0xFFB0B4AC), // stone
    ],
  );

  /// Status colours are darkened for contrast on paper, and [accent] becomes
  /// a deep moss — the lime cannot carry white text at 4.5:1, so it moves to
  /// [accentFill].
  static const light = AppColors(
    background: Color(0xFFF4F6EF),
    elevated: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    pressed: Color(0xFFE7EBE0),
    textPrimary: Color(0xFF171A14),
    textSecondary: Color(0xFF596052),
    textMuted: Color(0xFF5E6557),
    border: Color(0x16000000), // translucent black
    borderStrong: Color(0x26000000),
    hairline: Color(0x66FFFFFF),
    accent: Color(0xFF42600A),
    accentDim: Color(0xFF35500A),
    onAccent: Color(0xFFFFFFFF),
    accentFill: Color(0xFF9ADB33),
    onAccentFill: Color(0xFF10150A),
    overdue: Color(0xFFA6403A),
    medium: Color(0xFF7A5714),
    done: Color(0xFF3E6A0C),
    low: Color(0xFF146966),
    decorative: [
      Color(0xFF4A5F3E), // sage
      Color(0xFF3E5460), // mist
      Color(0xFF514672), // lilac
      Color(0xFF6B4A36), // clay
      Color(0xFF5E5327), // sand
      Color(0xFF6B3F4A), // rose
      Color(0xFF42552F), // moss
      Color(0xFF4A4E46), // stone
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
