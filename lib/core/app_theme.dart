import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'chunky_border.dart';

abstract final class AppTheme {
  /// Nunito: rounded terminals and a friendly, heavy black weight, so the
  /// headings carry the meadow's warmth. Bundled in `assets/fonts/`.
  static const fontFamily = 'Nunito';

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  /// The lip under a pressable block: full when resting, nearly flat while
  /// the finger is down, so the block sinks.
  static const _lip = 4.0;
  static const _pressedLip = 1.0;

  /// A filled or outlined button as a chunky block with a solid bottom lip.
  /// The padding keeps the label centred on the face above the lip, and
  /// drops it with the face while pressed.
  static ButtonStyle _chunky(
    ButtonStyle base,
    AppColors c, {
    required Color edge,
    BorderSide? side,
  }) => base.copyWith(
    elevation: const WidgetStatePropertyAll(0),
    animationDuration: const Duration(milliseconds: 80),
    padding: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? const EdgeInsets.fromLTRB(20, _lip - _pressedLip, 20, _pressedLip)
          : const EdgeInsets.fromLTRB(20, 0, 20, _lip),
    ),
    shape: WidgetStateProperty.resolveWith(
      (states) => ChunkyBorder(
        radius: AppRadii.md,
        edge: states.contains(WidgetState.disabled) ? c.borderStrong : edge,
        depth: states.contains(WidgetState.pressed) ? _pressedLip : _lip,
        side: side ?? BorderSide.none,
      ),
    ),
  );

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.accentFill,
            brightness: brightness,
          ).copyWith(
            surface: c.background,
            surfaceContainerLow: c.elevated,
            surfaceContainer: c.card,
            surfaceContainerHigh: c.pressed,
            primary: c.accent,
            onPrimary: c.onAccent,
            primaryContainer: c.tintLeaf,
            onPrimaryContainer: c.textPrimary,
            secondary: c.accentDim,
            onSecondary: c.onAccent,
            secondaryContainer: c.tintLeaf,
            onSecondaryContainer: c.textPrimary,
            tertiary: c.streak,
            tertiaryContainer: c.tintSun,
            onTertiaryContainer: c.textPrimary,
            surfaceTint: Colors.transparent,
            onSurface: c.textPrimary,
            onSurfaceVariant: c.textSecondary,
            outline: c.borderStrong,
            outlineVariant: c.border,
            error: c.overdue,
          ),
      scaffoldBackgroundColor: c.background,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    TextStyle? styled(
      TextStyle? from,
      double size, {
      FontWeight? weight,
      Color? color,
      double? height,
    }) => from?.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: AppTypography.trackingFor(size),
    );

    // The outlined button's lip: its own border, solid.
    final quietEdge = Color.alphaBlend(c.borderStrong, c.card);

    return base.copyWith(
      extensions: [c],
      textTheme: textTheme.copyWith(
        titleLarge: styled(
          textTheme.titleLarge,
          AppTypography.title3,
          weight: FontWeight.w800,
        ),
        titleMedium: styled(
          textTheme.titleMedium,
          AppTypography.callout,
          weight: FontWeight.w800,
        ),
        titleSmall: styled(
          textTheme.titleSmall,
          AppTypography.body,
          weight: FontWeight.w700,
        ),
        bodyLarge: styled(
          textTheme.bodyLarge,
          AppTypography.callout,
          weight: FontWeight.w600,
        ),
        bodyMedium: styled(
          textTheme.bodyMedium,
          AppTypography.body,
          weight: FontWeight.w600,
          height: 1.35,
        ),
        bodySmall: styled(
          textTheme.bodySmall,
          AppTypography.footnote,
          weight: FontWeight.w600,
        ),
        labelLarge: styled(
          textTheme.labelLarge,
          AppTypography.body,
          weight: FontWeight.w800,
        ),
        labelMedium: styled(
          textTheme.labelMedium,
          AppTypography.footnote,
          weight: FontWeight.w700,
          color: c.textSecondary,
        ),
        labelSmall: styled(
          textTheme.labelSmall,
          AppTypography.caption,
          weight: FontWeight.w700,
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.accent,
        scaffoldBackgroundColor: c.background,
        barBackgroundColor: c.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: c.accent,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.callout,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
          actionTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.callout,
            fontWeight: FontWeight.w700,
            color: c.accent,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.callout,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.display,
            fontWeight: FontWeight.w900,
            letterSpacing: AppTypography.trackingFor(AppTypography.display),
            color: c.textPrimary,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.textPrimary,
          fontSize: AppTypography.title3,
          fontWeight: FontWeight.w800,
          letterSpacing: AppTypography.trackingFor(AppTypography.title3),
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.tintLeaf,
        indicatorShape: AppRadii.mediumShape,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: ChunkyBorder(
          radius: AppRadii.md,
          edge: quietEdge,
          depth: 3,
          side: BorderSide(color: c.border, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.elevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: AppRadii.sheetShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: AppRadii.largeShape,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.textPrimary,
          fontSize: AppTypography.title3,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.textSecondary,
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.hero,
        contentTextStyle: TextStyle(color: c.onHero),
        actionTextColor: c.accentFill,
        behavior: SnackBarBehavior.floating,
        shape: AppRadii.mediumShape,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accentFill,
        foregroundColor: c.onAccentFill,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 1,
        iconSize: 30,
        shape: ChunkyBorder(radius: AppRadii.md, edge: c.accentEdge),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accentFill : c.pressed,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : c.borderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accentFill,
        inactiveTrackColor: c.pressed,
        thumbColor: c.accentFill,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accentFill,
        linearTrackColor: c.pressed,
        circularTrackColor: c.pressed,
      ),
      // Round on both platforms: the iOS Reminders convention, filled with
      // the leaf green once it is done.
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: c.textMuted, width: 2),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accentFill
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onAccentFill),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        hintStyle: TextStyle(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.smallRadius,
          borderSide: BorderSide(color: c.borderStrong, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.smallRadius,
          borderSide: BorderSide(color: c.borderStrong, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smallRadius,
          borderSide: BorderSide(color: c.accentFill, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _chunky(
          FilledButton.styleFrom(
            backgroundColor: c.accentFill,
            foregroundColor: c.onAccentFill,
            disabledBackgroundColor: c.pressed,
            disabledForegroundColor: c.textMuted,
            minimumSize: const Size(48, 52),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: AppTypography.callout,
              fontWeight: FontWeight.w800,
            ),
          ),
          c,
          edge: c.accentEdge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _chunky(
          OutlinedButton.styleFrom(
            backgroundColor: c.card,
            foregroundColor: c.textPrimary,
            disabledForegroundColor: c.textMuted,
            minimumSize: const Size(48, 52),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: AppTypography.callout,
              fontWeight: FontWeight.w800,
            ),
          ),
          c,
          edge: quietEdge,
          side: BorderSide(color: c.borderStrong, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minVerticalPadding: AppSpacing.md,
      ),
      // The active filter is the loudest chip: a leaf-green pill.
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.accentFill,
        checkmarkColor: c.onAccentFill,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.textSecondary,
          fontSize: AppTypography.footnote,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.onAccentFill,
          fontSize: AppTypography.footnote,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: c.borderStrong, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: AppRadii.mediumShape,
          side: BorderSide(color: c.borderStrong, width: 1.5),
          backgroundColor: c.card,
          selectedBackgroundColor: c.accentFill,
          selectedForegroundColor: c.onAccentFill,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: c.card),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.hero,
        headerForegroundColor: c.onHero,
      ),
      // iOS does not ripple: widgets keep their highlight fade, which reads
      // as a native press. Android keeps Material's ripple.
      splashFactory: switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => NoSplash.splashFactory,
        _ => InkRipple.splashFactory,
      },
    );
  }
}
