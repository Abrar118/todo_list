import '../models/date_only.dart';
import '../models/priority.dart';
import '../models/task.dart';
import 'escalation.dart';

/// Grouped view of active tasks for the Focus screen.
class FocusSections {
  final List<Task> spotlight;
  final List<Task> overdue;
  final List<Task> today;
  final List<Task> upcoming;

  const FocusSections({
    required this.spotlight,
    required this.overdue,
    required this.today,
    required this.upcoming,
  });

  bool get isEmpty =>
      spotlight.isEmpty && overdue.isEmpty && today.isEmpty && upcoming.isEmpty;
}

/// Pure ordering logic for the Focus screen so the spotlight rules can be
/// unit tested.
class FocusArranger {
  static const int spotlightSize = 3;
  static const int upcomingPreviewSize = 4;

  const FocusArranger();

  FocusSections arrange(List<Task> tasks, DateTime now) {
    final today = DateOnly.fromDateTime(now);
    final active = tasks
        .where((t) => !t.isCompleted && t.kind != TaskKind.seriesTemplate)
        .toList();

    final spotlight = _spotlight(active, now, today);
    final spotlightIds = spotlight.map((t) => t.id).toSet();

    final overdue =
        active
            .where((t) => t.isOverdue(now) && !spotlightIds.contains(t.id))
            .toList()
          ..sort((a, b) => _compareDue(a, b));

    final dueToday =
        active
            .where(
              (t) =>
                  t.dueDate == today &&
                  !t.isOverdue(now) &&
                  !spotlightIds.contains(t.id),
            )
            .toList()
          ..sort((a, b) => _compareTodaySort(a, b));

    final upcoming =
        active
            .where(
              (t) =>
                  t.dueDate != null &&
                  t.dueDate!.isAfter(today) &&
                  !spotlightIds.contains(t.id),
            )
            .toList()
          ..sort((a, b) => _compareDue(a, b));

    return FocusSections(
      spotlight: spotlight,
      overdue: overdue,
      today: dueToday,
      upcoming: upcoming.take(upcomingPreviewSize).toList(),
    );
  }

  /// Spotlight priority, per spec:
  /// 1. overdue high-priority
  /// 2. high-priority due today
  /// 3. other overdue
  /// 4. high-priority upcoming
  /// 5. tasks with an active persistent reminder
  /// 6. nearest remaining deadline
  ///
  /// Escalation lifts a repeatedly put-off task by one tier per level, so a
  /// task ignored long enough always climbs back into the spotlight.
  List<Task> _spotlight(List<Task> active, DateTime now, DateOnly today) {
    int tier(Task t) {
      final overdue = t.isOverdue(now);
      final high = t.priority == TaskPriority.high;
      final dueToday = t.dueDate == today && !overdue;
      final base = overdue && high
          ? 0
          : high && dueToday
          ? 1
          : overdue
          ? 2
          : high && t.dueDate != null
          ? 3
          : t.hasAlarm
          ? 4
          : t.dueDate != null
          ? 5
          : 6;
      if (base >= 6) return base;
      final boosted = base - Escalation.level(t, now);
      return boosted < 0 ? 0 : boosted;
    }

    final candidates = active.where((t) => tier(t) < 6).toList()
      ..sort((a, b) {
        final ta = tier(a), tb = tier(b);
        if (ta != tb) return ta.compareTo(tb);
        return _compareDue(a, b);
      });
    return candidates.take(spotlightSize).toList();
  }

  /// Earlier deadline first; tasks with a time before date-only tasks on the
  /// same day; ties broken by priority then creation time.
  int _compareDue(Task a, Task b) {
    final da = a.dueDate, db = b.dueDate;
    if (da == null && db == null) return a.createdAt.compareTo(b.createdAt);
    if (da == null) return 1;
    if (db == null) return -1;
    final dateCmp = da.compareTo(db);
    if (dateCmp != 0) return dateCmp;
    final ma = a.dueMinutes ?? 24 * 60;
    final mb = b.dueMinutes ?? 24 * 60;
    if (ma != mb) return ma.compareTo(mb);
    final prio = b.priority.index.compareTo(a.priority.index);
    if (prio != 0) return prio;
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Today section sort, per spec: priority, deadline time, active reminder,
  /// creation time.
  int _compareTodaySort(Task a, Task b) {
    final prio = b.priority.index.compareTo(a.priority.index);
    if (prio != 0) return prio;
    final ma = a.dueMinutes ?? 24 * 60;
    final mb = b.dueMinutes ?? 24 * 60;
    if (ma != mb) return ma.compareTo(mb);
    final ra = a.hasAlarm || a.hasReminders ? 0 : 1;
    final rb = b.hasAlarm || b.hasReminders ? 0 : 1;
    if (ra != rb) return ra.compareTo(rb);
    return a.createdAt.compareTo(b.createdAt);
  }

  /// "2 hours overdue", "1 day overdue" labels.
  static String overdueLabel(Task task, DateTime now) {
    if (task.dueDate == null) return '';
    if (task.dueMinutes == null) {
      final days = DateOnly.fromDateTime(now).differenceInDays(task.dueDate!);
      return days == 1 ? '1 day overdue' : '$days days overdue';
    }
    final diff = now.difference(task.dueDate!.atMinutes(task.dueMinutes!));
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 day overdue' : '${diff.inDays} days overdue';
    }
    if (diff.inHours >= 1) {
      return diff.inHours == 1
          ? '1 hour overdue'
          : '${diff.inHours} hours overdue';
    }
    final mins = diff.inMinutes.clamp(1, 59);
    return mins == 1 ? '1 minute overdue' : '$mins minutes overdue';
  }
}
