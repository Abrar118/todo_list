import 'package:add_2_calendar/add_2_calendar.dart';

import '../domain/logic/task_search.dart';
import '../domain/models/task.dart';

/// One-way "Add to device calendar": opens the system calendar editor
/// pre-filled with the task, so no calendar permissions are ever needed.
/// Returns false when no calendar app could handle the request.
Future<bool> addTaskToDeviceCalendar(
  Task task, {
  int dateOnlyMinutes = 9 * 60,
}) async {
  final due = task.dueDate;
  if (due == null) return false;
  final allDay = task.dueMinutes == null;
  final start = due.atMinutes(task.dueMinutes ?? dateOnlyMinutes);
  try {
    return await Add2Calendar.addEvent2Cal(
      Event(
        title: task.title,
        description: TaskSearch.detailsPlainText(task.detailsJson).trim(),
        startDate: start,
        endDate: start.add(const Duration(minutes: 30)),
        allDay: allDay,
      ),
    );
  } catch (_) {
    return false;
  }
}
