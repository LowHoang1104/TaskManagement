import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/domain/entities/task_dependency_entity.dart';
import 'package:task_management/feature/presentation/providers/task_dependencies_provider.dart';

class MockTaskService extends Mock implements ITaskService {}

void main() {
  late TaskDependenciesNotifier notifier;
  late MockTaskService mockService;
  const tTaskId = 't1';

  final tDependency = TaskDependencyEntity(
    id: 'dep1',
    successorTaskId: tTaskId,
    predecessorTaskId: 't2',
    dependencyType: 'blocks',
    predecessorTaskTitle: 'Task 2',
  );

  setUp(() {
    mockService = MockTaskService();
    notifier = TaskDependenciesNotifier(mockService, tTaskId);
  });

  group('TaskDependenciesNotifier - fetchDependencies', () {
    test('should set dependencies when fetch is successful', () async {
      when(() => mockService.getTaskDependencies(tTaskId))
          .thenAnswer((_) async => Right([tDependency]));

      await notifier.fetchDependencies();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      expect(notifier.state.dependencies.length, 1);
      expect(notifier.state.dependencies.first.id, 'dep1');
    });

    test('should set error when fetch fails', () async {
      when(() => mockService.getTaskDependencies(tTaskId))
          .thenAnswer((_) async => const Left('Fetch Error'));

      await notifier.fetchDependencies();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
      expect(notifier.state.dependencies, isEmpty);
    });
  });

  group('TaskDependenciesNotifier - setDependency', () {
    test('should set dependency and refresh on success', () async {
      // 1. Success on setTaskDependency
      when(() => mockService.setTaskDependency(tTaskId, 't2', 'blocks'))
          .thenAnswer((_) async => const Right(true));
      
      // 2. Fetch is called automatically after success, so mock it too
      when(() => mockService.getTaskDependencies(tTaskId))
          .thenAnswer((_) async => Right([tDependency]));

      final result = await notifier.setDependency('t2', 'blocks');

      // fetchDependencies inside setDependency is async, wait for it
      await Future.delayed(Duration.zero);

      expect(result, true);
      expect(notifier.state.error, null);
      expect(notifier.state.dependencies.length, 1);
      verify(() => mockService.getTaskDependencies(tTaskId)).called(1);
    });

    test('should set error on setDependency failure', () async {
      when(() => mockService.setTaskDependency(tTaskId, 't2', 'blocks'))
          .thenAnswer((_) async => const Left('Set Error'));

      final result = await notifier.setDependency('t2', 'blocks');

      expect(result, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Set Error');
    });
  });
}
