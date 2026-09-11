import 'package:flutter/material.dart';

/// Nudge's palette as a theme extension so widgets follow the active theme.
/// Dark is the black-first wellness look; light is its clean paper equivalent.
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

  final Color accent;
  final Color accentDim;

  /// Foreground on accent-filled surfaces (FAB, filled buttons, checkmarks).
  final Color onAccent;

  final Color overdue;
  final Color medium;
  final Color done;
  final Color low;

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
    required this.overdue,
    required this.medium,
    required this.done,
    required this.low,
  });

  static const dark = AppColors(
    background: Color(0xFF090B09),
    elevated: Color(0xFF101310),
    card: Color(0xFF171A17),
    pressed: Color(0xFF20251F),
    textPrimary: Color(0xFFF6F8F1),
    textSecondary: Color(0xFFA8ADA1),
    textMuted: Color(0xFF747A70),
    border: Color(0x14FFFFFF), // translucent white
    borderStrong: Color(0x24FFFFFF),
    accent: Color(0xFFB7F23E),
    accentDim: Color(0xFF8FC72C),
    onAccent: Color(0xFF10150A),
    overdue: Color(0xFFD76B5F),
    medium: Color(0xFFE2C99D),
    done: Color(0xFF9ED83A),
    low: Color(0xFF76D7D0),
  );

  /// Status colors are darkened for contrast on paper.
  static const light = AppColors(
    background: Color(0xFFF4F6EF),
    elevated: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    pressed: Color(0xFFE7EBE0),
    textPrimary: Color(0xFF171A14),
    textSecondary: Color(0xFF596052),
    textMuted: Color(0xFF858C7C),
    border: Color(0x16000000), // translucent black
    borderStrong: Color(0x26000000),
    accent: Color(0xFF74A80E),
    accentDim: Color(0xFF5F9006),
    onAccent: Color(0xFFFFFFFF),
    overdue: Color(0xFFB84B43),
    medium: Color(0xFF8B651A),
    done: Color(0xFF568A10),
    low: Color(0xFF187C78),
  );

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
    Color? overdue,
    Color? medium,
    Color? done,
    Color? low,
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
    overdue: overdue ?? this.overdue,
    medium: medium ?? this.medium,
    done: done ?? this.done,
    low: low ?? this.low,
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
      overdue: mix(overdue, other.overdue),
      medium: mix(medium, other.medium),
      done: mix(done, other.done),
      low: mix(low, other.low),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
