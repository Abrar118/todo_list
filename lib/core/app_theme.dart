import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    const radius = 14.0;
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
            secondary: c.accentDim,
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

    return base.copyWith(
      extensions: [c],
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.35),
        labelMedium: textTheme.labelMedium?.copyWith(color: c.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.elevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accent.withValues(alpha: 0.14),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.elevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.textMuted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: c.textSecondary,
          fontSize: 14.5,
          height: 1.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.pressed,
        contentTextStyle: TextStyle(color: c.textPrimary),
        actionTextColor: c.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
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
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: BorderSide(color: c.textMuted, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.done
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        hintStyle: TextStyle(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.pressed.withValues(alpha: 0.72),
          side: BorderSide.none,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minVerticalPadding: 12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.accent.withValues(alpha: 0.18),
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: c.card),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.elevated,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
