import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/models/task.dart';

/// Storage boundary for tasks. The UI and controllers only ever talk to this
/// interface so a synced implementation can be swapped in later.
abstract class TaskRepository {
  Future<List<Task>> loadAll();
  Future<void> upsert(Task task);
  Future<void> upsertAll(List<Task> tasks);
  Future<void> delete(String id);
  Future<void> deleteMany(Iterable<String> ids);
  Future<void> deleteAll();
}

class SqfliteTaskRepository implements TaskRepository {
  final Database db;

  SqfliteTaskRepository(this.db);

  static const table = 'tasks';

  static Future<void> createSchema(Database db) async {
    // Full task state lives in the JSON payload (one serialization path
    // shared with import/export); indexed columns exist for queries only.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        series_id TEXT,
        due_date TEXT,
        payload TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_series ON $table(series_id)',
    );
  }

  @override
  Future<List<Task>> loadAll() async {
    final rows = await db.query(table);
    final tasks = <Task>[];
    for (final row in rows) {
      try {
        tasks.add(
          Task.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          ),
        );
      } on FormatException {
        // A corrupt row must not take the whole app down; skip it.
        continue;
      }
    }
    return tasks;
  }

  Map<String, Object?> _toRow(Task task) => {
    'id': task.id,
    'kind': task.kind.name,
    'completed': task.isCompleted ? 1 : 0,
    'series_id': task.seriesId,
    'due_date': task.dueDate?.toString(),
    'payload': jsonEncode(task.toJson()),
  };

  @override
  Future<void> upsert(Task task) async {
    await db.insert(
      table,
      _toRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> upsertAll(List<Task> tasks) async {
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        table,
        _toRow(task),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(table, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteAll() async {
    await db.delete(table);
  }
}
