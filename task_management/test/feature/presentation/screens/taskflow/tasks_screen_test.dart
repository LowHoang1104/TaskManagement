import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/feature/presentation/providers/workspace_provider.dart';
import 'package:task_management/feature/application/i_services/i_workspace_service.dart';
import 'package:task_management/feature/presentation/taskflow/screens/tasks_screen.dart';
import 'package:task_management/feature/presentation/taskflow/taskflow_providers.dart';
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';
import 'package:task_management/core/di/injection_container.dart' as di;

class MockWorkspaceService extends Mock implements IWorkspaceService {}

class MockSignalRService extends Mock implements SignalRService {}

class MockWorkspaceNotifier extends WorkspaceNotifier with Mock {
  MockWorkspaceNotifier(super.service);
  @override
  Future<void> fetchWorkspaces() async {}
}

void main() {
  final sampleTask = TaskEntity(
    id: '1',
    projectId: 'p1',
    title: 'Design UI',
    description: '',
    status: TaskStatus.todo,
    priority: TaskPriority.high,
    assigneeId: null,
    reporterId: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    deadline: DateTime.now().add(const Duration(days: 1)), // upcoming
    order: 0,
    relations: [],
  );

  final sampleTaskWithProject = TaskWithProject(
    sampleTask,
    'Project Alpha',
    'w1',
  );

  setUp(() {
    // WorkspaceNotifier's constructor reads SignalRService from GetIt, so a
    // mock must be registered before the screen is built.
    final mockSignalR = MockSignalRService();
    when(() => mockSignalR.workspaceRefreshStream)
        .thenAnswer((_) => const Stream<String>.empty());
    if (di.sl.isRegistered<SignalRService>()) {
      di.sl.unregister<SignalRService>();
    }
    di.sl.registerSingleton<SignalRService>(mockSignalR);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Widget createTasksScreen({AsyncValue<List<TaskWithProject>> tasksState = const AsyncValue.data([])}) {
    return ProviderScope(
      overrides: [
        workspaceNotifierProvider.overrideWith((ref) {
          final mock = MockWorkspaceNotifier(MockWorkspaceService());
          mock.state = WorkspaceState(workspaces: [
            WorkspaceEntity(id: 'w1', name: 'W1', description: '', ownerId: 'u1', createdAt: DateTime.now(), updatedAt: DateTime.now())
          ]);
          return mock;
        }),
        allMyTasksProvider.overrideWith((ref) {
          return tasksState.when(
            data: (d) => Future.value(d),
            error: (e, s) => Future.error(e, s),
            loading: () => Completer<List<TaskWithProject>>().future,
          );
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TasksScreen()),
      ),
    );
  }

  group('TasksScreen Widget Tests', () {
    testWidgets('shows loading indicator when tasks are loading', (WidgetTester tester) async {
      await tester.pumpWidget(createTasksScreen(tasksState: const AsyncValue.loading()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when tasks fail to load', (WidgetTester tester) async {
      await tester.pumpWidget(createTasksScreen(tasksState: AsyncValue.error('Network error', StackTrace.empty)));
      await tester.pumpAndSettle();
      expect(find.text('Could not load tasks'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('displays tasks and allows filtering', (WidgetTester tester) async {
      await tester.pumpWidget(createTasksScreen(tasksState: AsyncValue.data([sampleTaskWithProject])));

      expect(find.text('My Tasks'), findsOneWidget);
      
      // Tap on the Upcoming bucket
      await tester.tap(find.textContaining('Upcoming'));
      await tester.pumpAndSettle();

      // Ensure the task is displayed in Upcoming
      expect(find.text('Design UI'), findsOneWidget);
      expect(find.textContaining('Project Alpha'), findsOneWidget);
    });

    testWidgets('search functionality filters tasks', (WidgetTester tester) async {
      await tester.pumpWidget(createTasksScreen(tasksState: AsyncValue.data([sampleTaskWithProject])));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'NoMatchText');
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);

      await tester.enterText(searchField, 'Design UI');
      await tester.pumpAndSettle();

      expect(find.text('Design UI'), findsWidgets);
    });
  });
}