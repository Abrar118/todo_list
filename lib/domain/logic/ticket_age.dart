import '../models/date_only.dart';
import '../models/task.dart';
import 'escalation.dart';

/// Where a task stands against its deadline, for the stamp a Focus row
/// prints at its right edge.
enum TicketTiming { none, late, dueToday, upcoming }

/// The stamp on a task's ticket: how late it is (or when it is due) and how
/// hot it has run.
///
/// [heat] is the one variable the Focus screen colours: 0 is ink, 1 is the
/// heat lamp (warming), 2 is thermal red (critical). A late task is always at
/// least warming, even before it has earned an [Escalation] level, because
/// lateness is the first thing a stamp has to say.
///
/// Pure Dart; [now] is injected so every rule is unit-testable.
class TicketAge {
  final TicketTiming timing;

  /// Whole calendar days past the due date; 0 means it fell due earlier
  /// today. Only meaningful when [timing] is [TicketTiming.late].
  final int daysLate;

  /// Days until the due date; only meaningful for [TicketTiming.upcoming].
  final int daysUntil;

  final int heat;

  const TicketAge({
    required this.timing,
    required this.heat,
    this.daysLate = 0,
    this.daysUntil = 0,
  });

  factory TicketAge.of(Task task, DateTime now) {
    final level = Escalation.level(task, now);
    final due = task.dueDate;
    if (due == null || task.isCompleted) {
      return TicketAge(timing: TicketTiming.none, heat: level);
    }
    final today = DateOnly.fromDateTime(now);
    if (task.isOverdue(now)) {
      return TicketAge(
        timing: TicketTiming.late,
        daysLate: today.differenceInDays(due),
        heat: level < 1 ? 1 : level,
      );
    }
    if (due == today) {
      return TicketAge(timing: TicketTiming.dueToday, heat: level);
    }
    return TicketAge(
      timing: TicketTiming.upcoming,
      daysUntil: due.differenceInDays(today),
      heat: level,
    );
  }
}
