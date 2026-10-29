import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import '../../core/formats.dart';
import '../../domain/logic/ticket_age.dart';
import '../../domain/models/task.dart';

/// The one colour Focus uses: heat. Ink when cold, the heat lamp when a
/// ticket is warming, thermal red when it has gone critical.
Color heatColor(AppColors colors, int heat) => switch (heat) {
  <= 0 => colors.textSecondary,
  1 => colors.medium,
  _ => colors.overdue,
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

  const PunchMarks({super.key, required this.count, required this.color});

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
              // A hole punched through the ticket: the steel ground shows
              // through, rimmed in the ticket's heat colour. Hollow, so it
              // can never be mistaken for a swatch's identity dot.
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.background,
                  border: Border.all(color: color, width: 1.5),
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

/// One ticket on the rail: a row inside a white run of tickets on the steel
/// ground. The run's top and bottom tickets round its corners and every
/// ticket after the first is separated by a hairline, so a section reads as
/// one strip of paper rather than a stack of floating cards.
class RailTile extends StatelessWidget {
  final Widget child;
  final bool first;
  final bool last;

  const RailTile({
    super.key,
    required this.child,
    this.first = false,
    this.last = false,
  });

  /// Where the hairline starts: past the completion control, so it underlines
  /// the text column like a ruled ticket.
  static const dividerIndent = 52.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.vertical(
      top: first ? const Radius.circular(AppRadii.md) : Radius.zero,
      bottom: last ? const Radius.circular(AppRadii.md) : Radius.zero,
    );
    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: colors.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!first)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: dividerIndent,
                color: colors.border,
              ),
            child,
          ],
        ),
      ),
    );
  }
}
