import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'task_repository.dart';

class AppDatabase {
  static const _name = 'nudge.db';
  static const _version = 1;

  static Future<Database> open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _name),
      version: _version,
      onCreate: (db, version) => SqfliteTaskRepository.createSchema(db),
    );
  }
}
