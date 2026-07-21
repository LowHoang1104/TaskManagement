import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/domain/entities/task_entity.dart';
import 'package:task_management/feature/domain/entities/enums.dart';
import 'package:task_management/feature/presentation/providers/task_provider.dart';
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';
import 'package:task_management/core/di/injection_container.dart' as di;

class MockTaskService extends Mock implements ITaskService {}

class MockSignalRService extends Mock implements SignalRService {}

void main() {
  late MockTaskService mockTaskService;
  late TaskNotifier notifier;

  final testTask = TaskEntity(
    id: '1',
    projectId: 'p1',
    title: 'Test Task',
    description: '',
    status: TaskStatus.todo,
    priority: TaskPriority.high,
    assigneeId: null,
    reporterId: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    order: 0,
    relations: [],
  );

  setUp(() {
    // TaskNotifier's constructor reads SignalRService from GetIt, so a mock
    // must be registered before it is built.
    final mockSignalR = MockSignalRService();
    when(() => mockSignalR.projectRefreshStream)
        .thenAnswer((_) => const Stream<String>.empty());
    if (di.sl.isRegistered<SignalRService>()) {
      di.sl.unregister<SignalRService>();
    }
    di.sl.registerSingleton<SignalRService>(mockSignalR);

    mockTaskService = MockTaskService();
    // The constructor also calls fetchTasks(), so getTasks must be stubbed
    // before the notifier is built. Individual tests re-stub as needed.
    when(() => mockTaskService.getTasks('p1'))
        .thenAnswer((_) async => const Right(<TaskEntity>[]));
    notifier = TaskNotifier(mockTaskService, 'p1');
  });

  tearDown(() async {
    await di.sl.reset();
  });

  group('fetchTasks', () {
    test('sets tasks on success', () async {
      when(() => mockTaskService.getTasks('p1')).thenAnswer((_) async => Right([testTask]));

      await notifier.fetchTasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first, testTask);
    });

    test('sets error on failure', () async {
      when(() => mockTaskService.getTasks('p1')).thenAnswer((_) async => const Left('Failed to fetch'));

      await notifier.fetchTasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Failed to fetch');
      expect(notifier.state.tasks.isEmpty, true);
    });
  });

  group('createTask', () {
    test('adds task to state on success', () async {
      when(() => mockTaskService.createTask('p1', 'New Task', 'Desc', TaskStatus.todo, TaskPriority.medium, assigneeId: null))
          .thenAnswer((_) async => Right(testTask));

      final result = await notifier.createTask('New Task', 'Desc', TaskStatus.todo, TaskPriority.medium);

      expect(result, testTask);
      expect(notifier.state.tasks.contains(testTask), true);
    });

    test('sets error and returns null on failure', () async {
      when(() => mockTaskService.createTask('p1', 'New Task', 'Desc', TaskStatus.todo, TaskPriority.medium, assigneeId: null))
          .thenAnswer((_) async => const Left('Creation failed'));

      final result = await notifier.createTask('New Task', 'Desc', TaskStatus.todo, TaskPriority.medium);

      expect(result, isNull);
      expect(notifier.state.error, 'Creation failed');
    });
  });

  group('deleteTask', () {
    test('removes task from state on success', () async {
      notifier.state = TaskState(tasks: [testTask]);
      when(() => mockTaskService.deleteTask('p1', '1')).thenAnswer((_) async => const Right(true));

      final success = await notifier.deleteTask('1');

      expect(success, true);
      expect(notifier.state.tasks.isEmpty, true);
    });

    test('sets error and returns false on failure', () async {
      notifier.state = TaskState(tasks: [testTask]);
      when(() => mockTaskService.deleteTask('p1', '1')).thenAnswer((_) async => const Left('Delete failed'));

      final success = await notifier.deleteTask('1');

      expect(success, false);
      expect(notifier.state.error, 'Delete failed');
      expect(notifier.state.tasks.length, 1);
    });
  });

  group('updateTask', () {
    final updatedTask = testTask.copyWith(status: TaskStatus.done);

    test('updateTaskStatusLocally updates state and calls service on success', () async {
      notifier.state = TaskState(tasks: [testTask]);
      when(() => mockTaskService.updateTaskStatus('p1', '1', TaskStatus.done))
          .thenAnswer((_) async => Right(updatedTask));

      await notifier.updateTaskStatusLocally('1', TaskStatus.done);

      // Status should be updated locally first, then kept on success
      expect(notifier.state.tasks.first.status, TaskStatus.done);
      expect(notifier.state.error, isNull);
    });

    test('updateTaskStatusLocally reverts state on failure', () async {
      notifier.state = TaskState(tasks: [testTask]);
      when(() => mockTaskService.updateTaskStatus('p1', '1', TaskStatus.done))
          .thenAnswer((_) async => const Left('Update failed'));

      await notifier.updateTaskStatusLocally('1', TaskStatus.done);

      // Reverts to old status on failure
      expect(notifier.state.tasks.first.status, TaskStatus.todo);
      expect(notifier.state.error, 'Update failed');
    });

    test('updateTaskAssignee calls service and updates state on success', () async {
      notifier.state = TaskState(tasks: [testTask]);
      final assignedTask = testTask.copyWith(assigneeId: 'u2');
      when(() => mockTaskService.updateTaskAssignee('p1', '1', 'u2'))
          .thenAnswer((_) async => Right(assignedTask));

      await notifier.updateTaskAssignee('1', 'u2');

      expect(notifier.state.tasks.first.assigneeId, 'u2');
      expect(notifier.state.error, isNull);
    });
  });
}