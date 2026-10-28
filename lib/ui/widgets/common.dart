import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/task.dart';
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

/// The colour behind a task card. Decorative, never semantic — a task tinted
/// "Rose" must not be mistaken for a high-priority one. Shared by the row and
/// the editor's swatches so the two can never drift apart.
Color taskBackgroundColor(AppColors colors, TaskBackground background) =>
    switch (background) {
      TaskBackground.automatic => colors.decorative[0],
      TaskBackground.lime => colors.decorative[0], // sage
      TaskBackground.cyan => colors.decorative[1], // mist
      TaskBackground.sand => colors.decorative[4], // sand
      TaskBackground.coral => colors.decorative[5], // rose
    };

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

/// A root screen's header: an iOS-style large title that collapses to inline
/// on scroll. Pushed screens keep a plain inline [AppBar], as iOS does.
SliverAppBar largeTitleAppBar({required Widget title, List<Widget>? actions}) =>
    SliverAppBar(
      pinned: true,
      expandedHeight: AppLayout.largeTitleHeight,
      // Transparent so the shell's backdrop runs behind the title instead of
      // stopping at a seam along the app bar's bottom edge.
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: actions,
      // The title lives only here, so it is one widget in the tree rather
      // than the two SliverAppBar.large builds, and the gap below it is ours
      // to set instead of the framework's fixed 28.
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          bottom: AppLayout.largeTitleGap,
        ),
        expandedTitleScale: AppLayout.largeTitleScale,
        title: title,
      ),
    );

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
