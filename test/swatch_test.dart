import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/core/app_colors.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/goal.dart';
import 'package:todo_list/domain/models/habit.dart';
import 'package:todo_list/domain/models/swatch.dart';
import 'package:todo_list/domain/models/task.dart';

void main() {
  test('every swatch has a colour in both themes', () {
    expect(AppColors.dark.decorative, hasLength(Swatch.values.length));
    expect(AppColors.light.decorative, hasLength(Swatch.values.length));
  });

  group('legacy colour names still resolve', () {
    // The three subsystems had their own enums with colliding names: `violet`
    // rendered sage on a habit but lilac on a goal. Existing data and v1
    // backups must keep looking exactly as they did.
    test('task backgrounds', () {
      final base = Task(
        id: 't',
        title: 'x',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ).toJson();
      Swatch? read(String name) =>
          Task.fromJson({...base, 'background': name}).background;

      expect(read('lime'), Swatch.sage);
      expect(read('cyan'), Swatch.mist);
      expect(read('sand'), Swatch.sand);
      expect(read('coral'), Swatch.rose);
      expect(Task.fromJson(base).background, isNull, reason: 'automatic');
    });

    test('habit colours', () {
      final base = Habit(
        id: 'h',
        title: 'x',
        color: Swatch.moss,
        createdOn: const DateOnly(2026, 1, 1),
        completedDates: const {},
      ).toJson();
      Swatch read(String name) =>
          Habit.fromJson({...base, 'color': name}).color;

      expect(read('violet'), Swatch.sage);
      expect(read('blue'), Swatch.mist);
      expect(read('green'), Swatch.moss);
      expect(read('amber'), Swatch.sand);
      expect(read('rose'), Swatch.rose);
      expect(read('nonsense'), Swatch.moss, reason: 'falls back to default');
    });

    test('goal colours', () {
      final base = Goal(
        id: 'g',
        title: 'x',
        targetDate: const DateOnly(2026, 2, 1),
        createdOn: const DateOnly(2026, 1, 1),
        color: Swatch.sage,
      ).toJson();
      Swatch read(String name) => Goal.fromJson({...base, 'color': name}).color;

      expect(read('lime'), Swatch.sage);
      expect(read('cyan'), Swatch.mist);
      expect(read('amber'), Swatch.sand);
      expect(read('coral'), Swatch.rose);
      expect(read('violet'), Swatch.lilac);
    });

    test('new swatch names round-trip', () {
      for (final swatch in Swatch.values) {
        final goal = Goal(
          id: 'g',
          title: 'x',
          targetDate: const DateOnly(2026, 2, 1),
          createdOn: const DateOnly(2026, 1, 1),
          color: swatch,
        );
        expect(Goal.fromJson(goal.toJson()).color, swatch);
      }
    });
  });
}
