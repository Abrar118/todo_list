import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/logic/escalation.dart';
import '../../domain/logic/focus_arranger.dart';
import '../../domain/logic/ticket_age.dart';
import '../../domain/models/priority.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/task.dart';
import 'common.dart';
import 'ticket.dart';

/// The shared task row used by Focus, Calendar, Search and Completed. It
/// draws no surface of its own: on Focus and Calendar a [TaskCard] supplies
/// the chunky white block around it.
///
/// With [stamp], the row prints its ticket stamp at the right edge: when it
/// is due or how late it is, coloured by heat, with a punch mark per time it
/// was put off. Calendar and search rows already sit under a date, so they
/// leave it off and show the deadline inline instead.
class TaskRow extends StatelessWidget {
  final Task task;
  final RecurrenceRule? rule;
  final bool compact;
  final bool showOverdue;
  final bool isProjection;

  /// Shows the user's chosen swatch as a small identity mark by the title.
  final bool showTaskBackground;
  final bool stamp;

  /// Strikes the title through ahead of completion, so a ticket is visibly
  /// spiked before it leaves the rail.
  final bool striking;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onSnooze;

  const TaskRow({
    super.key,
    required this.task,
    this.rule,
    this.compact = false,
    this.showOverdue = false,
    this.isProjection = false,
    this.showTaskBackground = false,
    this.stamp = false,
    this.striking = false,
    this.onTap,
    this.onToggle,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final age = TicketAge.of(task, now);
    final overdue = showOverdue && task.isOverdue(now);
    final struck = task.isCompleted || striking;
    final muted = struck || isProjection;
    final stampValue = stamp ? stampText(task, age) : null;
    // Keyed to completion, not to the strike: a ticket being spiked keeps
    // its stamp, so the row doesn't reflow while it slides off the rail.
    final showStamp =
        stamp &&
        !task.isCompleted &&
        (stampValue != null || task.deferralCount > 0);

    final chips = <Widget>[];
    if (task.dueDate != null && !showStamp) {
      chips.add(
        MetaChip(
          icon: Icons.schedule_outlined,
          label: overdue
              ? FocusArranger.overdueLabel(task, now)
              : Formats.deadline(task.dueDate!, task.dueMinutes),
          color: overdue ? heatColor(colors, age.heat) : null,
        ),
      );
    }
    if (task.priority != TaskPriority.none) {
      chips.add(
        MetaChip(
          icon: priorityIcon(task.priority),
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
      if (!compact) {
        for (final tag in task.tags.take(3)) {
          chips.add(MetaChip(label: '#$tag'));
        }
      }
      if (task.tags.length > 3) {
        chips.add(MetaChip(label: '+${task.tags.length - 3}'));
      }
    }
    if (task.isRecurring) {
      chips.add(
        MetaChip(
          icon: Icons.repeat,
          label: rule != null && !compact ? rule!.describe() : 'Repeats',
        ),
      );
    }
    if (task.hasAlarm) {
      chips.add(
        const MetaChip(
          icon: Icons.notifications_active_outlined,
          label: 'Alarm on',
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
        ),
      );
    }
    final escalation = task.isCompleted ? null : Escalation.describe(task, now);
    // With a stamp, the punch marks already say this.
    if (escalation != null && !showStamp) {
      chips.add(
        MetaChip(
          icon: Icons.local_fire_department_outlined,
          label: escalation,
          color: heatColor(colors, age.heat),
        ),
      );
    }

    final semanticsLabel = [
      task.title,
      if (task.priority != TaskPriority.none) '${task.priority.label} priority',
      if (showStamp && stampValue != null)
        '${stampValue.caption} ${stampValue.value}'.trim()
      else if (overdue)
        FocusArranger.overdueLabel(task, now),
      ?escalation,
      if (task.isCompleted) 'completed',
    ].join(', ');

    final swatch = showTaskBackground ? task.background : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xs,
          compact ? AppSpacing.xs / 2 : AppSpacing.sm,
          AppSpacing.md,
          compact ? AppSpacing.xs / 2 : AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (isProjection)
              SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.repeat, size: 20, color: colors.textMuted),
              )
            else
              Semantics(
                label: task.isCompleted
                    ? 'Mark ${task.title} as not completed'
                    : 'Complete ${task.title}',
                child: SizedBox(
                  // 44pt: the iOS minimum. The box is the tap target; the
                  // checkbox itself draws smaller.
                  width: 44,
                  height: 44,
                  child: Checkbox(
                    value: struck,
                    onChanged: onToggle == null ? null : (_) => onToggle!(),
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
                    Row(
                      children: [
                        if (swatch != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: swatchColor(colors, swatch),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppTypography.callout,
                              fontWeight: FontWeight.w800,
                              color: muted
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              decoration: struck
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textMuted,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (chips.isNotEmpty && !compact) ...[
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 2,
                        children: chips,
                      ),
                    ],
                    if (!compact && !task.isCompleted)
                      if (task.progress case final progress?
                          when progress > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _Progress(progress: progress),
                      ],
                  ],
                ),
              ),
            ),
            if (showStamp)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: ExcludeSemantics(
                  child: TicketStamp(task: task, age: age),
                ),
              ),
            if (onSnooze != null && (task.hasAlarm || task.isSnoozed))
              IconButton(
                tooltip: 'Snooze reminder',
                onPressed: onSnooze,
                icon: Icon(Icons.snooze, size: 20, color: colors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final double progress;

  const _Progress({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadii.pillRadius,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: colors.accentFill,
              backgroundColor: colors.pressed,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
