import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/swatch.dart';
import 'meadow.dart';

/// Red and amber are reserved for lateness, so priority speaks in ink: high
/// priority is set in full ink (and drawn with a filled flag, see
/// [priorityIcon]) so it never outshouts a task that is actually late.
Color priorityColor(BuildContext context, TaskPriority priority) {
  final colors = context.colors;
  return switch (priority) {
    TaskPriority.high => colors.textPrimary,
    TaskPriority.medium || TaskPriority.low => colors.textSecondary,
    TaskPriority.none => colors.textMuted,
  };
}

/// The flag for a priority: filled for high, outlined otherwise.
IconData priorityIcon(TaskPriority priority) =>
    priority == TaskPriority.high ? Icons.flag : Icons.flag_outlined;

/// Whether the app should speak iOS (HIG) rather than Android (Material 3).
/// Nudge adapts its chrome per OS: tab bar and nav-bar add button on iPhone,
/// navigation bar and FAB on Android.
bool isCupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Bottom padding for a root tab's scrolling content: clears the home
/// indicator when there is one and, on Android, the FAB.
double listBottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom +
    AppSpacing.lg +
    (isCupertino(context) ? 0 : 72);

/// The add action for a root tab on Android, where a screen's single primary
/// action is a FAB. Null on iOS, where the same action sits in the nav bar
/// (see [rootAppBar]'s `onAdd`).
Widget? rootAddFab(
  BuildContext context, {
  required VoidCallback onPressed,
  required String tooltip,
}) => isCupertino(context)
    ? null
    : FloatingActionButton(
        // Every tab in the shell's IndexedStack has its own FAB, so they
        // cannot share the default hero tag.
        heroTag: null,
        tooltip: tooltip,
        onPressed: onPressed,
        child: const Icon(Icons.add_rounded),
      );

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
                    color: icon == null ? colors.card : colors.textPrimary,
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A root tab's header, in each platform's own form: an iOS large title
/// that collapses on scroll, or a Material top app bar. Both are painted the
/// meadow's grass green so they run straight into the tab's [MeadowHeader].
/// [onAdd] puts the tab's add action in the iOS nav bar; Android shows it as
/// a FAB instead (see [rootAddFab]).
Widget rootAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  VoidCallback? onAdd,
  String addTooltip = 'Add',
}) {
  final colors = context.colors;
  if (isCupertino(context)) {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(title),
      backgroundColor: colors.meadowTop,
      border: null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions,
          if (onAdd != null)
            IconButton(
              tooltip: addTooltip,
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.add),
            ),
        ],
      ),
    );
  }
  return SliverAppBar(
    pinned: true,
    backgroundColor: colors.meadowTop,
    title: Text(
      title,
      style: const TextStyle(
        fontSize: AppTypography.title1,
        fontWeight: FontWeight.w900,
      ),
    ),
    actions: [
      ...actions,
      const SizedBox(width: AppSpacing.xs),
    ],
  );
}

/// The one empty state every tab uses: the tab's illustration, a heading
/// that says what is true, a sentence that teaches what the screen is for,
/// and the chunky button that fills it.
class EmptyState extends StatelessWidget {
  final Art art;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyState({
    super.key,
    required this.art,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Illustration(art, size: 112),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.title3,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.body,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// A list section's heading: sentence case, heavy, set in ink.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  /// Drops the leading air for the first header in a list, where the header
  /// already has the app bar above it and does not need separating from a
  /// previous section.
  final bool tight;

  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
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
            title,
            style: TextStyle(
              fontSize: AppTypography.callout,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: AppTypography.footnote,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
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
  final result = await showAdaptiveDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        dialogAction(
          context,
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        dialogAction(
          context,
          label: confirmLabel,
          destructive: destructive,
          isDefault: !destructive,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A dialog button in the platform's own form, for [AlertDialog.adaptive]:
/// a [CupertinoDialogAction] on iOS, a [TextButton] on Android.
Widget dialogAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  bool destructive = false,
  bool isDefault = false,
}) {
  if (isCupertino(context)) {
    return CupertinoDialogAction(
      isDestructiveAction: destructive,
      isDefaultAction: isDefault,
      onPressed: onPressed,
      child: Text(label),
    );
  }
  return TextButton(
    onPressed: onPressed,
    style: destructive
        ? TextButton.styleFrom(foregroundColor: context.colors.overdue)
        : null,
    child: Text(label),
  );
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
          // A dark-forest slip, the hero card's colour. It sits in an
          // overlay outside the app's Material, so the Material here also
          // supplies the text defaults — without it the text falls back to
          // monospace with yellow underlines.
          child: Material(
            color: colors.hero,
            shape: AppRadii.mediumShape,
            elevation: 6,
            shadowColor: const Color(0x66000000),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: colors.onHero,
                        fontSize: AppTypography.footnote,
                        fontWeight: FontWeight.w700,
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
                            color: colors.accentFill,
                            fontSize: AppTypography.footnote,
                            fontWeight: FontWeight.w900,
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
