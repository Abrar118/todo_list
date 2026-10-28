import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/core/app_colors.dart';
import 'package:todo_list/core/app_tokens.dart';

/// WCAG 2.x contrast ratio. [Color.computeLuminance] is the spec's relative
/// luminance, so this is the whole formula.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('palette contrast', () {
    for (final (themeName, c) in [
      ('dark', AppColors.dark),
      ('light', AppColors.light),
    ]) {
      final surfaces = {
        'background': c.background,
        'card': c.card,
        'pressed': c.pressed,
      };

      // Anything that can end up as text or as a meaningful icon.
      final onSurface = {
        'textPrimary': c.textPrimary,
        'textSecondary': c.textSecondary,
        'textMuted': c.textMuted,
        'accent': c.accent,
        'overdue': c.overdue,
        'medium': c.medium,
        'done': c.done,
        'low': c.low,
        for (final (i, color) in c.decorative.indexed) 'decorative[$i]': color,
      };

      test('$themeName: text colours clear 4.5:1 on every surface', () {
        for (final (fg, color) in onSurface.entries.map(
          (e) => (e.key, e.value),
        )) {
          for (final (bg, surface) in surfaces.entries.map(
            (e) => (e.key, e.value),
          )) {
            expect(
              contrast(color, surface),
              greaterThanOrEqualTo(4.5),
              reason: '$themeName $fg on $bg',
            );
          }
        }
      });

      test('$themeName: accentDim clears 3:1 (non-text use only)', () {
        for (final (bg, surface) in surfaces.entries.map(
          (e) => (e.key, e.value),
        )) {
          expect(
            contrast(c.accentDim, surface),
            greaterThanOrEqualTo(3.0),
            reason: '$themeName accentDim on $bg',
          );
        }
      });

      test('$themeName: accent fills carry their own foreground', () {
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
        expect(
          contrast(c.onAccentFill, c.accentFill),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('decorative family', () {
    test('is kept apart from the semantic family by saturation', () {
      double saturation(Color color) {
        final hsl = HSLColor.fromColor(color);
        return hsl.saturation;
      }

      final semantic = [
        AppColors.dark.accent,
        AppColors.dark.overdue,
        AppColors.dark.medium,
        AppColors.dark.done,
        AppColors.dark.low,
      ].map(saturation);
      // 'stone' is an intentional neutral, so compare against the rest.
      final decorative = AppColors.dark.decorative
          .map(saturation)
          .where((s) => s > 0.1);

      expect(
        decorative.reduce((a, b) => a > b ? a : b),
        lessThan(semantic.reduce((a, b) => a < b ? a : b)),
        reason:
            'the quietest semantic colour must still out-saturate the '
            'loudest decorative one, or the two families read as one',
      );
    });

    test('decorativeFor is stable and spreads across the palette', () {
      final c = AppColors.dark;
      expect(c.decorativeFor('work'), c.decorativeFor('work'));
      expect(c.decorativeFor('Work'), c.decorativeFor('work'));

      const tags = [
        'work',
        'home',
        'errands',
        'health',
        'reading',
        'finance',
        'family',
        'garden',
      ];
      final used = tags.map(c.decorativeFor).toSet();
      expect(
        used.length,
        greaterThanOrEqualTo(4),
        reason: 'a hash that collides this often would make tag colour noise',
      );
    });

    test('lerp keeps the decorative list intact', () {
      final mid = AppColors.dark.lerp(AppColors.light, 0.5);
      expect(mid.decorative, hasLength(AppColors.dark.decorative.length));
    });
  });

  group('scales', () {
    test('type scale is strictly ascending with no half-points', () {
      const sizes = [
        AppTypography.caption,
        AppTypography.footnote,
        AppTypography.body,
        AppTypography.callout,
        AppTypography.title3,
        AppTypography.title1,
        AppTypography.display,
        AppTypography.figure,
        AppTypography.figureLarge,
      ];
      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i], greaterThan(sizes[i - 1]));
      }
      for (final size in sizes) {
        expect(size % 1, 0, reason: '$size is a half-point');
      }
    });

    test('spacing follows the 4/8 rhythm', () {
      for (final step in [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ]) {
        expect(step % 4, 0, reason: '$step is off the 4pt grid');
      }
    });

    test('shapes use continuous corners', () {
      expect(AppRadii.mediumShape, isA<RoundedSuperellipseBorder>());
      expect(AppRadii.sheetShape, isA<RoundedSuperellipseBorder>());
    });
  });
}
