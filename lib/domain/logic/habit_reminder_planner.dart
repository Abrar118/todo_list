import '../models/habit.dart';

class PlannedHabitReminder {
  final int id;
  final String habitId;
  final String? checkpointId;
  final int minutesOfDay;
  final String title;
  final String body;

  const PlannedHabitReminder({
    required this.id,
    required this.habitId,
    required this.minutesOfDay,
    required this.title,
    required this.body,
    this.checkpointId,
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
            body: 'Time for your daily habit',
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
          ),
        );
      }
    }
    result.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return result;
  }

  static bool ownsId(int id) => (id & 0x70000000) == idPrefix;

  static int stableId(String habitId, String slotId) {
    var hash = 17;
    for (final code in '$habitId:$slotId'.codeUnits) {
      hash = (hash * 31 + code) & idMask;
    }
    return idPrefix | hash;
  }
}
