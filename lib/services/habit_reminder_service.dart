import '../domain/logic/habit_reminder_planner.dart';

abstract class HabitReminderService {
  Future<void> syncHabitReminders(List<PlannedHabitReminder> plan);
}
