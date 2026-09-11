import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/formats.dart';
import '../../domain/logic/escalation.dart';
import '../../domain/logic/focus_arranger.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/task.dart';
import 'common.dart';

/// The shared task row used by Focus, Calendar and Completed. The
/// [spotlight] variant gets a stronger card treatment with a very subtle
/// accent glow.
class TaskRow extends StatelessWidget {
  final Task task;
  final RecurrenceRule? rule;
  final bool spotlight;
  final bool compact;
  final bool showOverdue;
  final bool isProjection;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = spotlight ? 18.0 : 14.0;
    final tintAmount = task.priority == TaskPriority.none ? 0.05 : 0.20;

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
        chips.add(MetaChip(label: '#$tag'));
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
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: spotlight ? 0.14 : 0.08),
            blurRadius: spotlight ? 24 : 18,
            spreadRadius: -4,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      colors.card,
                      severityColor,
                      tintAmount,
                    )!.withValues(alpha: isDark ? 0.82 : 0.88),
                    Color.lerp(
                      colors.elevated,
                      severityColor,
                      tintAmount * 0.55,
                    )!.withValues(alpha: isDark ? 0.68 : 0.80),
                  ],
                ),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                highlightColor: colors.pressed,
                splashColor: severityColor.withValues(alpha: 0.12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: compact ? 6 : (spotlight ? 14 : 10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isProjection)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.repeat,
                            size: 20,
                            color: colors.textMuted,
                          ),
                        )
                      else
                        Semantics(
                          label: task.isCompleted
                              ? 'Mark ${task.title} as not completed'
                              : 'Complete ${task.title}',
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Checkbox(
                              value: task.isCompleted,
                              onChanged: onToggle == null
                                  ? null
                                  : (_) => onToggle!(),
                            ),
                          ),
                        ),
                      const SizedBox(width: 2),
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
                                  fontSize: spotlight ? 16 : 15,
                                  fontWeight: spotlight
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: chips,
                                ),
                              ],
                              if (!compact && !task.isCompleted)
                                if (task.progress case final progress?
                                    when progress > 0) ...[
                                  const SizedBox(height: 7),
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
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(progress * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 11,
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
                      if (onSnooze != null && (task.hasAlarm || task.isSnoozed))
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
            ),
          ),
        ),
      ),
    );
  }
}
