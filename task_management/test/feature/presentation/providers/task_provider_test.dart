import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/domain/entities/task_entity.dart';
import 'package:task_management/feature/domain/entities/enums.dart';
import 'package:task_management/feature/presentation/providers/task_provider.dart';

class MockTaskService extends Mock implements ITaskService {}

void main() {
  late TaskNotifier notifier;
  late MockTaskService mockService;
  const tProjectId = 'p1';
  const tTaskId = 't1';

  final tTask = TaskEntity(
    id: tTaskId,
    projectId: tProjectId,
    title: 'Test Task',
    description: 'Desc',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    assigneeId: 'u1',
    reporterId: 'u2',
    order: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    relations: const [],
  );

  setUp(() {
    mockService = MockTaskService();
    notifier = TaskNotifier(mockService, tProjectId);
  });

  group('TaskNotifier - fetchTasks', () {
    test('should set tasks when fetch is successful', () async {
      when(() => mockService.getTasks(tProjectId))
          .thenAnswer((_) async => Right([tTask]));

      await notifier.fetchTasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.first.id, tTaskId);
    });

    test('should set error when fetch fails', () async {
      when(() => mockService.getTasks(tProjectId))
          .thenAnswer((_) async => const Left('Fetch Error'));

      await notifier.fetchTasks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
      expect(notifier.state.tasks, isEmpty);
    });
  });

  group('TaskNotifier - createTask', () {
    test('should add task to state and return it on success', () async {
      when(() => mockService.createTask(tProjectId, 'Test Task', 'Desc', TaskStatus.todo, TaskPriority.medium))
          .thenAnswer((_) async => Right(tTask));

      final result = await notifier.createTask('Test Task', 'Desc', TaskStatus.todo, TaskPriority.medium);

      expect(result, tTask);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.tasks.last.id, tTaskId);
    });

    test('should return null and set error on failure', () async {
      when(() => mockService.createTask(tProjectId, 'Test Task', 'Desc', TaskStatus.todo, TaskPriority.medium))
          .thenAnswer((_) async => const Left('Create Error'));

      final result = await notifier.createTask('Test Task', 'Desc', TaskStatus.todo, TaskPriority.medium);

      expect(result, null);
      expect(notifier.state.error, 'Create Error');
    });
  });

  group('TaskNotifier - deleteTask', () {
    test('should remove task from state on success', () async {
      // Setup state first
      when(() => mockService.getTasks(tProjectId)).thenAnswer((_) async => Right([tTask]));
      await notifier.fetchTasks();
      
      when(() => mockService.deleteTask(tProjectId, tTaskId))
          .thenAnswer((_) async => const Right(true));

      final result = await notifier.deleteTask(tTaskId);

      expect(result, true);
      expect(notifier.state.tasks, isEmpty);
    });

    test('should set error on failure', () async {
      when(() => mockService.deleteTask(tProjectId, tTaskId))
          .thenAnswer((_) async => const Left('Delete Error'));

      final result = await notifier.deleteTask(tTaskId);

      expect(result, false);
      expect(notifier.state.error, 'Delete Error');
    });
  });

  group('TaskNotifier - updateTaskStatusLocally', () {
    test('should update status optimistically and revert on failure', () async {
      // Setup initial state
      when(() => mockService.getTasks(tProjectId)).thenAnswer((_) async => Right([tTask]));
      await notifier.fetchTasks();
      
      // Stub the update to fail
      when(() => mockService.updateTaskStatus(tProjectId, tTaskId, TaskStatus.doing))
          .thenAnswer((_) async => const Left('Update Error'));
      
      // Perform local update
      await notifier.updateTaskStatusLocally(tTaskId, TaskStatus.doing);
      
      // Since we awaited it, it reverted back to the old state because of error
      expect(notifier.state.error, 'Update Error');
      expect(notifier.state.tasks.first.status, TaskStatus.todo);
    });
    
    test('should update status optimistically and keep on success', () async {
      // Setup initial state
      when(() => mockService.getTasks(tProjectId)).thenAnswer((_) async => Right([tTask]));
      await notifier.fetchTasks();
      
      // Stub the update to succeed
      final updatedTask = tTask.copyWith(status: TaskStatus.done);
      when(() => mockService.updateTaskStatus(tProjectId, tTaskId, TaskStatus.done))
          .thenAnswer((_) async => Right(updatedTask));
      
      // Perform local update
      await notifier.updateTaskStatusLocally(tTaskId, TaskStatus.done);
      
      expect(notifier.state.error, null);
      expect(notifier.state.tasks.first.status, TaskStatus.done);
    });
  });
}
