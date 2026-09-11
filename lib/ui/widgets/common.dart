import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../domain/models/priority.dart';

Color priorityColor(BuildContext context, TaskPriority priority) {
  final colors = context.colors;
  return switch (priority) {
    TaskPriority.high => colors.overdue,
    TaskPriority.medium => colors.medium,
    TaskPriority.low => colors.low,
    TaskPriority.none => colors.textMuted,
  };
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
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? color;

  const SectionHeader(this.title, {super.key, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: color ?? colors.textMuted,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
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
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: destructive ? colors.overdue : colors.accent,
              ),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}
