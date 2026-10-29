import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/swatch.dart';
import 'glass_surface.dart';

Color priorityColor(BuildContext context, TaskPriority priority) {
  final colors = context.colors;
  return switch (priority) {
    TaskPriority.high => colors.overdue,
    TaskPriority.medium => colors.medium,
    TaskPriority.low => colors.low,
    TaskPriority.none => colors.textMuted,
  };
}

/// Resolves a [Swatch] against the active theme. Decorative, never semantic —
/// a task tinted "Rose" must not be mistaken for a high-priority one. Shared
/// by task rows, habits, goals and every picker, so they cannot drift apart.
Color swatchColor(AppColors colors, Swatch swatch) =>
    colors.decorative[swatch.index];

/// The grid of colour choices used by the task, habit and goal editors.
/// [onPick] receives null when the user taps the optional automatic cell.
class SwatchPicker extends StatelessWidget {
  final Swatch? selected;

  /// Adds a leading "automatic" cell that selects no swatch. Tasks use it for
  /// their priority-derived card treatment; habits and goals always have one.
  final bool allowAutomatic;
  final ValueChanged<Swatch?> onPick;

  const SwatchPicker({
    super.key,
    required this.selected,
    required this.onPick,
    this.allowAutomatic = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (allowAutomatic)
          _SwatchCell(
            color: colors.textMuted,
            label: 'Automatic',
            selected: selected == null,
            icon: Icons.auto_awesome_rounded,
            onTap: () => onPick(null),
          ),
        for (final swatch in Swatch.values)
          _SwatchCell(
            color: swatchColor(colors, swatch),
            label: swatch.label,
            selected: selected == swatch,
            onTap: () => onPick(swatch),
          ),
      ],
    );
  }
}

class _SwatchCell extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _SwatchCell({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: icon == null ? color : color.withValues(alpha: 0.18),
              border: Border.all(
                color: selected ? colors.textPrimary : colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 20,
                    // On a filled swatch the glyph sits on the colour; the
                    // automatic cell is only tinted, so it needs ink.
                    color: icon == null
                        ? colors.background
                        : colors.textPrimary,
                  )
                : icon == null
                ? null
                : Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

/// Small text+shape chip used in task rows. Never relies on color alone —
/// each chip carries a label or icon.
class MetaChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;

  const MetaChip({super.key, this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.footnote,
            color: c,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A root screen's header. The title sits inline in the toolbar row next to
/// the actions. An iOS large title puts it in a 104pt header below that row,
/// which leaves the toolbar visibly empty on the left until the page is
/// scrolled, so the pattern is deliberately not used here. Pushed screens use
/// a plain [AppBar], which already looks like this.
SliverAppBar rootAppBar({required Widget title, List<Widget>? actions}) =>
    SliverAppBar(
      pinned: true,
      title: title,
      // Transparent so the shell's backdrop runs behind the bar instead of
      // stopping at a seam along its bottom edge. Glass appears only once
      // content scrolls under it; without it the title sat on top of the rows.
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      flexibleSpace: const _ScrolledUnderGlass(),
      actions: actions,
    );

/// Chrome glass behind a pinned app bar, shown only while content is under
/// it. At rest it paints nothing, so there is no seam and no blur to pay for.
class _ScrolledUnderGlass extends StatelessWidget {
  const _ScrolledUnderGlass();

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (!(settings?.isScrolledUnder ?? false)) return const SizedBox.shrink();
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The app bar lays flexibleSpace out with loose constraints, so it has to
    // ask for the full height itself.
    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: AppGlass.chromeFilter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background.withValues(
                alpha: isDark
                    ? AppGlass.fillOpacityDark
                    : AppGlass.fillOpacityLight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: colors.border,
                  width: AppGlass.hairlineWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? color;

  /// Drops the leading air for the first header in a list, where the header
  /// already has the app bar above it and does not need separating from a
  /// previous section.
  final bool tight;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.color,
    this.tight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        tight ? AppSpacing.xs : AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: AppTypography.caption,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: color ?? colors.textMuted,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

OverlayEntry? _currentToast;

/// A brief confirmation, anchored at the top like an iOS banner. Keeps the
/// snackbar call signature so every caller stays put; only the presentation
/// changed. Timer-driven rather than animation-driven, so it stays on screen
/// across a `pumpAndSettle` exactly as the snackbar it replaces did.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  _currentToast?.remove();
  _currentToast = null;

  late final OverlayEntry entry;
  void dismiss() {
    if (_currentToast == entry) _currentToast = null;
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismissed: dismiss,
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _Toast({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 4);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    reverseDuration: AppMotion.quick,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(_visibleFor, _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curve,
      reverseCurve: AppMotion.exitCurve,
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(curved),
          child: GlassSurface.panel(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
            // An overlay sits outside the app's Material, so without this the
            // text falls back to Flutter's unstyled default — monospace with
            // yellow underlines.
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: AppTypography.footnote,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          widget.onAction!();
                          _dismiss();
                        },
                        child: Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: AppTypography.footnote,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
