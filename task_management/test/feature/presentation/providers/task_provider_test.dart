import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/domain/entities/task_entity.dart';
import 'package:task_management/feature/domain/entities/enums.dart';
import 'package:task_management/feature/presentation/providers/task_provider.dart';

class MockTaskService extends Mock implements ITaskService {}

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
    mockTaskService = MockTaskService();
    notifier = TaskNotifier(mockTaskService, 'p1');
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
}
