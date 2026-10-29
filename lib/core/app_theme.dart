import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.accent,
            brightness: brightness,
          ).copyWith(
            surface: c.background,
            surfaceContainerLow: c.elevated,
            surfaceContainer: c.card,
            surfaceContainerHigh: c.pressed,
            primary: c.accent,
            onPrimary: c.onAccent,
            // Every container role is a neutral from the palette: a seed
            // colour would otherwise tint selections (segmented buttons,
            // chips, the nav indicator) with a hue the world never chose.
            primaryContainer: c.pressed,
            onPrimaryContainer: c.textPrimary,
            secondary: c.accentDim,
            onSecondary: c.onAccent,
            secondaryContainer: c.pressed,
            onSecondaryContainer: c.textPrimary,
            tertiary: c.accentDim,
            tertiaryContainer: c.pressed,
            onTertiaryContainer: c.textPrimary,
            surfaceTint: Colors.transparent,
            onSurface: c.textPrimary,
            onSurfaceVariant: c.textSecondary,
            outline: c.border,
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

    return base.copyWith(
      extensions: [c],
      textTheme: textTheme.copyWith(
        titleLarge: styled(
          textTheme.titleLarge,
          AppTypography.title3,
          weight: FontWeight.w600,
        ),
        titleMedium: styled(
          textTheme.titleMedium,
          AppTypography.callout,
          weight: FontWeight.w600,
        ),
        titleSmall: styled(
          textTheme.titleSmall,
          AppTypography.body,
          weight: FontWeight.w600,
        ),
        bodyLarge: styled(textTheme.bodyLarge, AppTypography.callout),
        bodyMedium: styled(
          textTheme.bodyMedium,
          AppTypography.body,
          height: 1.35,
        ),
        bodySmall: styled(textTheme.bodySmall, AppTypography.footnote),
        labelLarge: styled(
          textTheme.labelLarge,
          AppTypography.body,
          weight: FontWeight.w600,
        ),
        labelMedium: styled(
          textTheme.labelMedium,
          AppTypography.footnote,
          color: c.textSecondary,
        ),
        labelSmall: styled(textTheme.labelSmall, AppTypography.caption),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Content passing under the bar lifts it with a hairline shadow
        // rather than a tint, so the steel ground stays one colour.
        scrolledUnderElevation: 1,
        shadowColor: c.borderStrong,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: AppTypography.title3,
          fontWeight: FontWeight.w600,
          letterSpacing: AppTypography.trackingFor(AppTypography.title3),
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.elevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.pressed,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppRadii.mediumShape,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.elevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.textMuted,
        shape: AppRadii.sheetShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: AppRadii.mediumShape,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: AppTypography.callout,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: c.textSecondary,
          fontSize: AppTypography.body,
          height: 1.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.pressed,
        contentTextStyle: TextStyle(color: c.textPrimary),
        actionTextColor: c.accent,
        behavior: SnackBarBehavior.floating,
        shape: AppRadii.mediumShape,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 2,
        shape: AppRadii.mediumShape,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (brightness == Brightness.dark ? c.textPrimary : c.elevated)
              : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accentDim : c.pressed,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.borderStrong),
      ),
      // Round on both platforms: the iOS Reminders convention, and a punched
      // hole in the ticket once it is done.
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: c.textMuted, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.textPrimary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.background),
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
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.smallRadius,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smallRadius,
          borderSide: BorderSide(color: c.accentDim),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(44, 44),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          minimumSize: const Size(44, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: AppRadii.mediumShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderStrong),
          minimumSize: const Size(44, 48),
          shape: AppRadii.mediumShape,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minVerticalPadding: AppSpacing.md,
      ),
      // Selected chips are inked like a punched selection, so the active
      // filter is the loudest chip, never the quietest.
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.textPrimary,
        checkmarkColor: c.background,
        labelStyle: TextStyle(
          color: c.textSecondary,
          fontSize: AppTypography.footnote,
        ),
        secondaryLabelStyle: TextStyle(
          color: c.background,
          fontSize: AppTypography.footnote,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: AppRadii.smallShape,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: AppRadii.mediumShape,
          selectedBackgroundColor: c.textPrimary,
          selectedForegroundColor: c.background,
        ),
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: c.card),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.elevated,
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
