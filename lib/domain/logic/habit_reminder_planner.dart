import '../models/habit.dart';
import '../models/notification_tone.dart';

class PlannedHabitReminder {
  final int id;
  final String habitId;
  final String? checkpointId;
  final int minutesOfDay;
  final String title;
  final String body;
  final NotificationTone tone;
  final HabitCadence cadence;
  final int? dayOfMonth;

  const PlannedHabitReminder({
    required this.id,
    required this.habitId,
    required this.minutesOfDay,
    required this.title,
    required this.body,
    this.checkpointId,
    required this.tone,
    required this.cadence,
    this.dayOfMonth,
  });
}

class HabitReminderPlanner {
  static const int idPrefix = 0x60000000;
  static const int idMask = 0x0fffffff;

  const HabitReminderPlanner();

  List<PlannedHabitReminder> plan(List<Habit> habits) {
    final result = <PlannedHabitReminder>[];
    for (final habit in habits) {
      final minutes = habit.scheduledMinutes;
      if (minutes != null) {
        result.add(
          PlannedHabitReminder(
            id: stableId(habit.id, 'habit'),
            habitId: habit.id,
            minutesOfDay: minutes,
            title: habit.title,
            body: habit.cadence == HabitCadence.daily
                ? 'Time for your daily habit'
                : 'Time for your monthly habit',
            tone: _toneForHabit(habit),
            cadence: habit.cadence,
            dayOfMonth: habit.cadence == HabitCadence.monthly
                ? habit.monthlyDay
                : null,
          ),
        );
      }
      for (final checkpoint in habit.checkpoints) {
        final checkpointMinutes = checkpoint.scheduledMinutes;
        if (checkpointMinutes == null) continue;
        result.add(
          PlannedHabitReminder(
            id: stableId(habit.id, checkpoint.id),
            habitId: habit.id,
            checkpointId: checkpoint.id,
            minutesOfDay: checkpointMinutes,
            title: habit.title,
            body: checkpoint.title,
            tone: _toneForHabit(habit),
            cadence: habit.cadence,
            dayOfMonth: habit.cadence == HabitCadence.monthly
                ? habit.monthlyDay
                : null,
          ),
        );
      }
    }
    result.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return result;
  }

  NotificationTone _toneForHabit(Habit habit) =>
      NotificationTone.forSwatch(habit.color);

  static bool ownsId(int id) => (id & 0x70000000) == idPrefix;

  static int stableId(String habitId, String slotId) {
    var hash = 17;
    for (final code in '$habitId:$slotId'.codeUnits) {
      hash = (hash * 31 + code) & idMask;
    }
    return idPrefix | hash;
  }
}
