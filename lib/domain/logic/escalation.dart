import '../models/date_only.dart';
import '../models/task.dart';

/// How persistently a task is being put off.
///
/// The score counts every explicit deferral (snooze or deadline move) plus
/// every full day the task has been overdue. Levels derived from the score
/// drive the escalation behavior elsewhere:
///
/// - [FocusArranger] promotes escalated tasks toward the spotlight.
/// - [NotificationPlanner] adds a daily "still waiting" nudge for escalated
///   overdue tasks whose one-shot reminders have already fired.
/// - The task row shows how often a task has been put off.
///
/// Pure Dart; [now] is injected so every rule is unit-testable.
abstract final class Escalation {
  /// Score at which a task is considered to need attention (level 1).
  static const int attentionScore = 3;

  /// Score at which a task is escalated aggressively (level 2).
  static const int criticalScore = 6;

  static int score(Task task, DateTime now) {
    if (task.isCompleted || task.kind == TaskKind.seriesTemplate) return 0;
    var s = task.deferralCount;
    final due = task.dueDate;
    if (due != null && task.isOverdue(now)) {
      s += DateOnly.fromDateTime(now).differenceInDays(due);
    }
    return s;
  }

  /// 0 = normal, 1 = needs attention, 2 = critical.
  static int level(Task task, DateTime now) {
    final s = score(task, now);
    if (s >= criticalScore) return 2;
    if (s >= attentionScore) return 1;
    return 0;
  }

  /// Row label, or null when the task is not escalated. Days overdue are
  /// already covered by the overdue label, so this focuses on deferrals.
  static String? describe(Task task, DateTime now) {
    if (task.deferralCount >= 2) return 'Put off ${task.deferralCount} times';
    return level(task, now) >= 1 ? 'Needs attention' : null;
  }
}
