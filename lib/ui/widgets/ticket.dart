import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/logic/ticket_age.dart';
import '../../domain/models/task.dart';
import 'meadow.dart';

/// Lateness speaks in heat: ink when a task is on time, amber when it is
/// warming, red when it has gone critical.
Color heatColor(AppColors colors, int heat) => switch (heat) {
  <= 0 => colors.textSecondary,
  1 => colors.medium,
  _ => colors.overdue,
};

/// [heatColor] for text on the dark-forest hero card.
Color heroHeatColor(AppColors colors, int heat) => switch (heat) {
  <= 0 => colors.onHeroMuted,
  1 => colors.heroWarm,
  _ => colors.heroHot,
};

/// What a ticket's stamp prints: a value set in tabular figures and the word
/// that says what the value means.
({String value, String caption})? stampText(
  Task task,
  TicketAge age,
) => switch (age.timing) {
  TicketTiming.none => null,
  TicketTiming.late when age.daysLate > 0 => (
    value: '${age.daysLate}d',
    caption: 'late',
  ),
  TicketTiming.late => (
    value: task.dueMinutes == null ? 'Today' : Formats.time(task.dueMinutes!),
    caption: 'late',
  ),
  TicketTiming.dueToday => (
    value: task.dueMinutes == null ? 'Today' : Formats.time(task.dueMinutes!),
    caption: 'due',
  ),
  // Under "Coming up" a date already means due; no caption.
  TicketTiming.upcoming => (
    value: Formats.stampDate(task.dueDate!),
    caption: '',
  ),
};

/// The right-hand stamp on a ticket: when it is due or how late it is, in
/// its heat colour, with a punch mark per time it was put off.
class TicketStamp extends StatelessWidget {
  final Task task;
  final TicketAge age;

  /// The pass prints its stamp at display size; rail rows print it small.
  final bool large;

  const TicketStamp({
    super.key,
    required this.task,
    required this.age,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = stampText(task, age);
    final color = heatColor(colors, age.heat);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (text != null) ...[
          Text(
            text.value,
            style: TextStyle(
              fontSize: large ? AppTypography.display : AppTypography.body,
              height: 1.1,
              fontWeight: age.heat > 0 ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: large
                  ? AppTypography.trackingFor(AppTypography.display)
                  : 0,
              color: age.heat > 0 ? color : colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (text.caption.isNotEmpty)
            Text(
              text.caption,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: age.heat > 0 ? color : colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
        if (task.deferralCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          PunchMarks(count: task.deferralCount, color: color),
        ],
      ],
    );
  }
}

/// One punched hole per time a task was put off, like a ticket clipped each
/// time it goes back on the rail. Five holes, then a count.
class PunchMarks extends StatelessWidget {
  final int count;
  final Color color;

  /// What shows through each hole: the surface the marks sit on.
  final Color? ground;

  const PunchMarks({
    super.key,
    required this.count,
    required this.color,
    this.ground,
  });

  static const _maxHoles = 5;

  @override
  Widget build(BuildContext context) {
    final holes = count.clamp(0, _maxHoles);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < holes; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
              // A hollow ring rimmed in the heat colour, so it can never be
              // mistaken for a swatch's solid identity dot.
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ground ?? context.colors.background,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
          if (count > _maxHoles)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '+${count - _maxHoles}',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One task as a chunky white card on the meadow, with a gap below it so a
/// section reads as a stack of blocks.
class TaskCard extends StatelessWidget {
  final Widget child;

  const TaskCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Material(
      color: context.colors.card,
      shape: chunkyCard(context.colors),
      clipBehavior: Clip.antiAlias,
      // Room for the lip, so content centres on the face.
      child: Padding(padding: const EdgeInsets.only(bottom: 3), child: child),
    ),
  );
}
