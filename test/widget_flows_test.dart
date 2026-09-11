import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:todo_list/domain/models/date_only.dart';
import 'package:todo_list/domain/models/recurrence.dart';
import 'package:todo_list/domain/models/task.dart';
import 'package:todo_list/main.dart';
import 'package:todo_list/services/home_widget_service.dart';
import 'package:todo_list/state/app_state.dart';
import 'package:todo_list/state/focus_timer_controller.dart';
import 'package:todo_list/state/habit_controller.dart';
import 'package:todo_list/state/settings_controller.dart';

import 'helpers/fakes.dart';

Future<(AppState, SettingsController)> buildApp(WidgetTester tester) async {
  final repo = InMemoryTaskRepository();
  final notifications = FakeNotificationService();
  final settingsRepo = InMemorySettingsRepository()..permissionRequested = true;
  final settings = SettingsController(settingsRepo, notifications);
  await settings.load();
  final state = AppState(repo, notifications, settings);
  await state.init();
  final habits = HabitController(InMemoryHabitRepository());
  await habits.init();
  await tester.pumpWidget(
    NudgeApp(
      appState: state,
      settingsController: settings,
      homeWidgets: HomeWidgetService(),
      focusTimer: FocusTimerController(state, settings, notifications),
      habitController: habits,
    ),
  );
  await tester.pumpAndSettle();
  return (state, settings);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty Focus shows the calm empty state', (tester) async {
    await buildApp(tester);
    expect(find.text('You are clear for now.'), findsOneWidget);
  });

  testWidgets('quick add creates a task due today', (tester) async {
    final (state, _) = await buildApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Call the plumber');
    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(state.allTasks.single.title, 'Call the plumber');
    expect(state.allTasks.single.dueDate, DateOnly.today());
    expect(find.text('Call the plumber'), findsOneWidget);
  });

  testWidgets('editor adds subtasks and completing parent asks about them', (
    tester,
  ) async {
    final (state, _) = await buildApp(tester);
    final task = await state.createTask(
      title: 'Plan trip',
      dueDate: DateOnly.today(),
    );
    await tester.pumpAndSettle();

    // Open the editor and add a subtask.
    await tester.tap(find.text('Plan trip'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Add subtask'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Add subtask'),
      'Book flights',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 600)); // autosave debounce
    expect(state.taskById(task.id)!.subtasks.single.title, 'Book flights');

    // Back to Focus.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Completing the parent with an incomplete subtask asks first.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This task still has incomplete subtasks. Complete everything?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Complete everything'));
    await tester.pumpAndSettle();

    final completed = state.taskById(task.id)!;
    expect(completed.isCompleted, isTrue);
    expect(completed.subtasks.single.isCompleted, isTrue);

    // Undo snackbar restores it.
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state.taskById(task.id)!.isCompleted, isFalse);
  });

  testWidgets('description keeps focus when a new line is inserted', (
    tester,
  ) async {
    final (state, _) = await buildApp(tester);
    await state.createTask(
      title: 'Write release notes',
      dueDate: DateOnly.today(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write release notes'));
    await tester.pumpAndSettle();

    final editorFinder = find.byType(QuillEditor);
    await tester.scrollUntilVisible(
      editorFinder,
      120,
      scrollable: find.byType(Scrollable).first,
    );

    var editor = tester.widget<QuillEditor>(editorFinder);
    editor.focusNode.requestFocus();
    await tester.pump();
    expect(editor.focusNode.hasFocus, isTrue);

    editor.controller.replaceText(
      0,
      0,
      'First line\nSecond line',
      const TextSelection.collapsed(offset: 22),
    );
    await tester.pump();

    editor = tester.widget<QuillEditor>(editorFinder);
    expect(editor.focusNode.hasFocus, isTrue);
  });

  testWidgets('calendar shows tasks for the selected date', (tester) async {
    final (state, _) = await buildApp(tester);
    await state.createTask(title: 'Calendar task', dueDate: DateOnly.today());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar task'), findsOneWidget);
  });

  testWidgets('completed screen lists and restores finished tasks', (
    tester,
  ) async {
    final (state, _) = await buildApp(tester);
    final task = await state.createTask(title: 'Finished thing');
    await state.completeTask(task);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Finished thing'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore task'));
    await tester.pumpAndSettle();
    expect(state.taskById(task.id)!.isCompleted, isFalse);
    expect(find.text('Completed tasks will appear here.'), findsOneWidget);
  });

  testWidgets('quick add parses natural-language dates', (tester) async {
    final (state, _) = await buildApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'call mom tomorrow');
    await tester.pump();
    expect(find.textContaining('Detected: Tomorrow'), findsOneWidget);

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(state.allTasks.single.title, 'call mom');
    expect(state.allTasks.single.dueDate, DateOnly.today().addDays(1));
  });

  testWidgets('swiping a Focus row opens the defer sheet', (tester) async {
    final (state, _) = await buildApp(tester);
    final task = await state.createTask(
      title: 'Slippery task',
      dueDate: DateOnly.today(),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Slippery task'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Move deadline'), findsOneWidget);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    final deferred = state.taskById(task.id)!;
    expect(deferred.dueDate, DateOnly.today().addDays(1));
    expect(deferred.deferralCount, 1);
  });

  testWidgets('quick add extracts #tags', (tester) async {
    final (state, _) = await buildApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'buy paint #home');
    await tester.pump();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(state.allTasks.single.title, 'buy paint');
    expect(state.allTasks.single.tags, ['home']);
  });

  testWidgets('Focus tag filter narrows the list', (tester) async {
    final (state, _) = await buildApp(tester);
    await state.createTask(
      title: 'Fix the sink',
      dueDate: DateOnly.today(),
      tags: const ['home'],
    );
    await state.createTask(
      title: 'Quarterly report',
      dueDate: DateOnly.today(),
      tags: const ['work'],
    );
    await tester.pumpAndSettle();

    expect(find.text('Fix the sink'), findsOneWidget);
    expect(find.text('Quarterly report'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '#home'));
    await tester.pumpAndSettle();
    expect(find.text('Fix the sink'), findsOneWidget);
    expect(find.text('Quarterly report'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Quarterly report'), findsOneWidget);
  });

  testWidgets('habit tracker adds and completes a daily habit', (tester) async {
    await buildApp(tester);

    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    expect(find.text('No habits yet'), findsOneWidget);

    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('habit-name-field')),
      'Drink water',
    );
    await tester.pump();
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('0 of 1 complete today'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark today complete'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 complete today'), findsOneWidget);
    expect(find.text('1 day streak'), findsOneWidget);
  });

  testWidgets('timer habit opens details and persists checkpoints', (
    tester,
  ) async {
    await buildApp(tester);

    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('habit-name-field')),
      'Daily workout',
    );
    await tester.tap(find.text('Timer'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daily workout'));
    await tester.pumpAndSettle();
    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Start timer'), findsOneWidget);

    await tester.tap(find.byTooltip('Add checkpoint'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('checkpoint-name-field')),
      'Warm up',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add checkpoint'));
    await tester.pumpAndSettle();
    expect(find.text('Warm up'), findsWidgets);
  });

  testWidgets('search finds tasks by title', (tester) async {
    final (state, _) = await buildApp(tester);
    await state.createTask(title: 'Call the plumber');
    await state.createTask(title: 'Water the plants');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search tasks'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'plumber');
    await tester.pumpAndSettle();

    expect(find.text('Call the plumber'), findsOneWidget);
    expect(find.text('Water the plants'), findsNothing);
  });

  testWidgets('recurring task row shows the repeat indicator', (tester) async {
    final (state, _) = await buildApp(tester);
    await state.createTask(
      title: 'Weekly sync',
      dueDate: DateOnly.today(),
      recurrence: RecurrenceRule.weekly(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weekly sync'), findsOneWidget);
    // Only the occurrence row is rendered, never the template. In the
    // spotlight the full rule description is shown.
    expect(
      state.allTasks.where((t) => t.kind == TaskKind.seriesTemplate).length,
      1,
    );
    expect(find.text('Every week'), findsWidgets);
  });
}
