import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/models/swatch.dart';
import 'package:todo_list/data/goal_repository.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/goal.dart';
import 'package:todo_list/state/goal_controller.dart';

class _MemoryGoalRepository implements GoalRepository {
  List<Goal> stored = [];

  @override
  Future<List<Goal>> loadAll() async => List.of(stored);

  @override
  Future<void> saveAll(List<Goal> goals) async => stored = List.of(goals);

  @override
  Future<void> deleteAll() async => stored.clear();
}

void main() {
  const today = DateOnly(2026, 9, 12);

  test('goal progress follows checkpoints when checkpoints exist', () {
    const goal = Goal(
      id: 'goal-1',
      title: 'Finish a book',
      targetDate: DateOnly(2026, 10, 1),
      createdOn: today,
      color: Swatch.sage,
      manualProgress: 80,
      checkpoints: [
        GoalCheckpoint(id: 'one', title: 'Read part one', isCompleted: true),
        GoalCheckpoint(id: 'two', title: 'Read part two'),
      ],
    );

    expect(goal.progress, .5);
    expect(goal.completedCheckpointCount, 1);
  });

  test('goal JSON round-trip preserves progress and checkpoints', () {
    const goal = Goal(
      id: 'goal-1',
      title: 'Ship the project',
      description: 'Complete the first public release.',
      targetDate: DateOnly(2026, 11, 10),
      createdOn: today,
      color: Swatch.mist,
      manualProgress: 35,
      checkpoints: [GoalCheckpoint(id: 'one', title: 'Build MVP')],
    );

    expect(Goal.fromJson(goal.toJson()), goal);
  });

  test('controller persists goal and checkpoint mutations', () async {
    final repository = _MemoryGoalRepository();
    final controller = GoalController(repository);
    await controller.init();
    await controller.addGoal(
      title: 'Fix sleep schedule',
      targetDate: const DateOnly(2026, 10, 1),
      color: Swatch.lilac,
      createdOn: today,
    );
    final goalId = controller.goals.single.id;
    await controller.addCheckpoint(goalId, title: 'Sleep before midnight');
    final checkpointId = controller.goals.single.checkpoints.single.id;
    await controller.toggleCheckpoint(goalId, checkpointId);

    expect(repository.stored.single.progress, 1);
    expect(repository.stored.single.checkpoints.single.isCompleted, isTrue);
  });
}
