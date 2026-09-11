import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_list/data/task_json_codec.dart';
import 'package:todo_list/data/task_repository.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/priority.dart';
import 'package:todo_list/domain/models/reminders.dart';
import 'package:todo_list/domain/models/subtask.dart';
import 'package:todo_list/domain/models/task.dart';

Task fullTask(String id) {
  final now = DateTime(2026, 7, 11, 9, 30);
  return Task(
    id: id,
    kind: TaskKind.occurrence,
    title: 'Fully loaded task',
    detailsJson: '[{"insert":"Some notes\\n"}]',
    priority: TaskPriority.high,
    dueDate: const DateOnly(2026, 7, 15),
    dueMinutes: 14 * 60,
    reminders: const [ReminderEntry.atDeadline(), ReminderEntry.before(60)],
    alarm: const AlarmConfig(
      enabled: true,
      cadenceMinutes: 30,
      stopMinutesOfDay: 22 * 60,
      allowInQuietHours: true,
      soundEnabled: false,
    ),
    snoozedUntil: now.add(const Duration(hours: 1)),
    deferralCount: 3,
    tags: const ['Work', 'errands'],
    progressPercent: 40,
    timeSpentSeconds: 1500,
    background: TaskBackground.cyan,
    seriesId: 'series-1',
    occurrenceDate: const DateOnly(2026, 7, 15),
    occurrenceIndex: 3,
    subtasks: [
      Subtask(
        id: 'sub1',
        title: 'First',
        sortIndex: 1,
        createdAt: now,
        isCompleted: true,
        completedAt: now,
      ),
      Subtask(id: 'sub2', title: 'Second', sortIndex: 0, createdAt: now),
    ],
    createdAt: now,
    updatedAt: now,
    sortIndex: 7,
  );
}

void expectTaskEquals(Task a, Task b) {
  expect(a.id, b.id);
  expect(a.kind, b.kind);
  expect(a.title, b.title);
  expect(a.detailsJson, b.detailsJson);
  expect(a.priority, b.priority);
  expect(a.isCompleted, b.isCompleted);
  expect(a.dueDate, b.dueDate);
  expect(a.dueMinutes, b.dueMinutes);
  expect(a.reminders, b.reminders);
  expect(a.alarm.enabled, b.alarm.enabled);
  expect(a.alarm.cadenceMinutes, b.alarm.cadenceMinutes);
  expect(a.alarm.stopMinutesOfDay, b.alarm.stopMinutesOfDay);
  expect(a.alarm.allowInQuietHours, b.alarm.allowInQuietHours);
  expect(a.alarm.soundEnabled, b.alarm.soundEnabled);
  expect(a.snoozedUntil, b.snoozedUntil);
  expect(a.deferralCount, b.deferralCount);
  expect(a.tags, b.tags);
  expect(a.progressPercent, b.progressPercent);
  expect(a.timeSpentSeconds, b.timeSpentSeconds);
  expect(a.background, b.background);
  expect(a.seriesId, b.seriesId);
  expect(a.occurrenceDate, b.occurrenceDate);
  expect(a.occurrenceIndex, b.occurrenceIndex);
  expect(a.subtasks.length, b.subtasks.length);
  for (var i = 0; i < a.subtasks.length; i++) {
    expect(a.subtasks[i].id, b.subtasks[i].id);
    expect(a.subtasks[i].title, b.subtasks[i].title);
    expect(a.subtasks[i].isCompleted, b.subtasks[i].isCompleted);
    expect(a.subtasks[i].sortIndex, b.subtasks[i].sortIndex);
  }
  expect(a.createdAt, b.createdAt);
  expect(a.updatedAt, b.updatedAt);
  expect(a.sortIndex, b.sortIndex);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqfliteTaskRepository', () {
    late Database db;
    late SqfliteTaskRepository repo;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await SqfliteTaskRepository.createSchema(db);
      repo = SqfliteTaskRepository(db);
    });

    tearDown(() => db.close());

    test('round-trips every field', () async {
      final task = fullTask('t1');
      await repo.upsert(task);
      final loaded = await repo.loadAll();
      expectTaskEquals(loaded.single, task);
    });

    test('upsert replaces existing rows', () async {
      await repo.upsert(fullTask('t1'));
      await repo.upsert(fullTask('t1').copyWith(title: 'Renamed'));
      final loaded = await repo.loadAll();
      expect(loaded.single.title, 'Renamed');
    });

    test('delete and deleteAll', () async {
      await repo.upsertAll([fullTask('a'), fullTask('b'), fullTask('c')]);
      await repo.delete('b');
      expect((await repo.loadAll()).map((t) => t.id).toSet(), {'a', 'c'});
      await repo.deleteAll();
      expect(await repo.loadAll(), isEmpty);
    });

    test('subtask ordering survives persistence', () async {
      await repo.upsert(fullTask('t1'));
      final loaded = (await repo.loadAll()).single;
      // Stored in insertion order; sortIndex preserved for UI ordering.
      expect(loaded.subtasks.map((s) => s.sortIndex), [1, 0]);
    });
  });

  group('TaskJsonCodec', () {
    const codec = TaskJsonCodec();

    test('export/import round-trip', () {
      final tasks = [fullTask('a'), fullTask('b')];
      final decoded = codec.decode(codec.encode(tasks));
      expect(decoded.length, 2);
      expectTaskEquals(decoded[0], tasks[0]);
      expectTaskEquals(decoded[1], tasks[1]);
    });

    test('older task JSON defaults to an automatic background', () {
      final json = fullTask('legacy').toJson()..remove('background');
      expect(Task.fromJson(json).background, TaskBackground.automatic);
    });

    test('rejects non-JSON', () {
      expect(() => codec.decode('not json'), throwsFormatException);
    });

    test('rejects foreign JSON', () {
      expect(() => codec.decode('{"foo": 1}'), throwsFormatException);
    });

    test('rejects invalid task entries', () {
      expect(
        () => codec.decode('{"app":"nudge","version":1,"tasks":[{"x":1}]}'),
        throwsFormatException,
      );
    });

    test('rejects newer format versions', () {
      expect(
        () => codec.decode('{"app":"nudge","version":99,"tasks":[]}'),
        throwsFormatException,
      );
    });
  });
}
