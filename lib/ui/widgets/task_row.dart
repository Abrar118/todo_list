import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/logic/escalation.dart';
import '../../domain/logic/focus_arranger.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/swatch.dart';
import '../../domain/models/task.dart';
import 'common.dart';

/// The shared task row used by Focus, Calendar and Completed. The
/// [spotlight] variant gets a stronger card treatment with a very subtle
/// accent glow.
///
/// Deliberately not a glass surface: rows sit directly on the scaffold
/// background, so a blur would sample a flat colour and return it unchanged
/// while costing a `saveLayer` per row on every frame. The tinted fill plus
/// the hairline does the same visual job for free.
class TaskRow extends StatelessWidget {
  final Task task;
  final RecurrenceRule? rule;
  final bool spotlight;
  final bool compact;
  final bool showOverdue;
  final bool isProjection;
  final bool showTaskBackground;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onSnooze;

  const TaskRow({
    super.key,
    required this.task,
    this.rule,
    this.spotlight = false,
    this.compact = false,
    this.showOverdue = false,
    this.isProjection = false,
    this.showTaskBackground = false,
    this.onTap,
    this.onToggle,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final overdue = showOverdue && task.isOverdue(now);
    final muted = task.isCompleted || isProjection;
    final severityColor = task.isCompleted
        ? colors.done
        : priorityColor(context, task.priority);
    final customBackground = showTaskBackground && task.background != null;
    final surfaceColor = customBackground
        ? swatchColor(colors, task.background!)
        : severityColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = spotlight ? AppRadii.md : AppRadii.sm + 2;
    final borderRadius = BorderRadius.circular(radius);
    final tintAmount = customBackground
        ? (isDark ? 0.26 : 0.18)
        : task.priority == TaskPriority.none
        ? 0.04
        : 0.16;

    final chips = <Widget>[];
    if (task.dueDate != null) {
      chips.add(
        MetaChip(
          icon: Icons.schedule_outlined,
          label: overdue
              ? FocusArranger.overdueLabel(task, now)
              : Formats.deadline(task.dueDate!, task.dueMinutes),
          color: overdue ? colors.overdue : null,
        ),
      );
    }
    if (task.priority != TaskPriority.none) {
      chips.add(
        MetaChip(
          icon: Icons.flag_outlined,
          label: task.priority.label,
          color: priorityColor(context, task.priority),
        ),
      );
    }
    if (task.subtasks.isNotEmpty) {
      chips.add(
        MetaChip(
          icon: Icons.checklist_outlined,
          label: '${task.completedSubtaskCount} of ${task.subtasks.length}',
        ),
      );
    }
    if (task.tags.isNotEmpty) {
      for (final tag in task.tags.take(3)) {
        chips.add(MetaChip(label: '#$tag', color: colors.decorativeFor(tag)));
      }
      if (task.tags.length > 3) {
        chips.add(MetaChip(label: '+${task.tags.length - 3}'));
      }
    }
    if (task.isRecurring) {
      chips.add(
        MetaChip(
          icon: Icons.repeat,
          label: rule != null && spotlight ? rule!.describe() : 'Repeats',
        ),
      );
    }
    if (task.hasAlarm) {
      chips.add(
        MetaChip(
          icon: Icons.notifications_active_outlined,
          label: 'Alarm on',
          color: colors.accent,
        ),
      );
    } else if (task.hasReminders) {
      chips.add(
        const MetaChip(icon: Icons.notifications_none, label: 'Reminder'),
      );
    }
    if (task.isSnoozed) {
      chips.add(
        MetaChip(
          icon: Icons.snooze,
          label: 'Snoozed until ${Formats.timeOf(task.snoozedUntil!)}',
          color: colors.medium,
        ),
      );
    }
    final escalation = task.isCompleted ? null : Escalation.describe(task, now);
    if (escalation != null) {
      chips.add(
        MetaChip(
          icon: Icons.local_fire_department_outlined,
          label: escalation,
          color: Escalation.level(task, now) >= 2
              ? colors.overdue
              : colors.medium,
        ),
      );
    }

    final semanticsLabel = [
      task.title,
      if (task.priority != TaskPriority.none) '${task.priority.label} priority',
      if (overdue) FocusArranger.overdueLabel(task, now),
      ?escalation,
      if (task.isCompleted) 'completed',
    ].join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: surfaceColor.withValues(alpha: spotlight ? 0.16 : 0.10),
            blurRadius: spotlight ? 24 : 18,
            spreadRadius: -4,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRSuperellipse(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(colors.card, surfaceColor, tintAmount)!,
                  Color.lerp(colors.elevated, surfaceColor, tintAmount * 0.55)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                if (customBackground)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _BackgroundMotif(
                        background: task.background!,
                        color: surfaceColor,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: onTap,
                  borderRadius: borderRadius,
                  highlightColor: colors.pressed,
                  splashColor: surfaceColor.withValues(alpha: 0.12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: compact
                          ? AppSpacing.xs
                          : (spotlight ? AppSpacing.md : AppSpacing.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isProjection)
                          const Padding(
                            padding: EdgeInsets.only(right: AppSpacing.sm),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.repeat, size: 20),
                            ),
                          )
                        else
                          Semantics(
                            label: task.isCompleted
                                ? 'Mark ${task.title} as not completed'
                                : 'Complete ${task.title}',
                            child: SizedBox(
                              // 44pt: the iOS minimum. The box is the tap
                              // target; the checkbox itself draws smaller.
                              width: 44,
                              height: 44,
                              child: Checkbox(
                                value: task.isCompleted,
                                onChanged: onToggle == null
                                    ? null
                                    : (_) => onToggle!(),
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Semantics(
                            label: semanticsLabel,
                            excludeSemantics: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: spotlight
                                        ? AppTypography.callout
                                        : AppTypography.body,
                                    fontWeight: spotlight
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    letterSpacing: AppTypography.trackingFor(
                                      spotlight
                                          ? AppTypography.callout
                                          : AppTypography.body,
                                    ),
                                    color: muted
                                        ? colors.textMuted
                                        : colors.textPrimary,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: colors.textMuted,
                                  ),
                                ),
                                if (chips.isNotEmpty && !compact) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    children: chips,
                                  ),
                                ],
                                if (!compact && !task.isCompleted)
                                  if (task.progress case final progress?
                                      when progress > 0) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 4,
                                              color: colors.done,
                                              backgroundColor: colors.pressed,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: AppTypography.caption,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        ),
                        if (onSnooze != null &&
                            (task.hasAlarm || task.isSnoozed))
                          IconButton(
                            tooltip: 'Snooze reminder',
                            onPressed: onSnooze,
                            icon: Icon(
                              Icons.snooze,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // The lit edge. Without it a light-mode card sits at ~1:1
                // against the page and is held up only by its shadow.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: borderRadius,
                          side: BorderSide(
                            color: colors.borderStrong,
                            width: AppGlass.hairlineWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundMotif extends StatelessWidget {
  final Swatch background;
  final Color color;

  const _BackgroundMotif({required this.background, required this.color});

  @override
  Widget build(BuildContext context) {
    // One motif per colour family rather than per swatch, so the twenty
    // choices stay four recognisable card treatments.
    final icon = switch (background) {
      Swatch.sage ||
      Swatch.moss ||
      Swatch.fern ||
      Swatch.olive ||
      Swatch.seafoam => Icons.eco_outlined,
      Swatch.mist ||
      Swatch.teal ||
      Swatch.sky ||
      Swatch.denim => Icons.water_drop_outlined,
      Swatch.sand ||
      Swatch.ochre ||
      Swatch.apricot ||
      Swatch.clay ||
      Swatch.stone => Icons.light_mode_outlined,
      Swatch.rose ||
      Swatch.lilac ||
      Swatch.iris ||
      Swatch.plum ||
      Swatch.berry ||
      Swatch.brick => Icons.favorite_border_rounded,
    };
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: -12,
          top: -24,
          child: Icon(icon, size: 104, color: color.withValues(alpha: .075)),
        ),
        Positioned(
          right: 78,
          bottom: -18,
          child: Icon(icon, size: 52, color: color.withValues(alpha: .045)),
        ),
      ],
    );
  }
}
