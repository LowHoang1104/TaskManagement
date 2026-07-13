import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/task_repository_imp.dart';
import 'package:task_management/feature/domain/entities/enums.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late TaskRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = TaskRepositoryImp(dio: mockDio);
  });

  final tTaskJson = {
    'id': 't1',
    'projectId': 'p1',
    'title': 'Test Task',
    'description': 'Desc',
    'status': 'todo',
    'priority': 'high',
    'assigneeId': 'u1',
    'reporterId': 'u2',
    'order': 1,
  };

  group('TaskRepositoryImp - getTasks', () {
    const tProjectId = 'p1';

    test('should return Right(List<TaskEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.byProject(tProjectId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.byProject(tProjectId)),
            data: [tTaskJson],
            statusCode: 200,
          ));

      final result = await repository.getTasks(tProjectId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 't1');
          expect(r.first.status, TaskStatus.todo);
          expect(r.first.priority, TaskPriority.high);
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(TaskEndpoints.byProject(tProjectId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.byProject(tProjectId)),
        message: 'Network Error',
      ));

      final result = await repository.getTasks(tProjectId);
      expect(result.isLeft(), true);
    });
  });

  group('TaskRepositoryImp - createTask', () {
    const tProjectId = 'p1';

    test('should return Right(TaskEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.byProject(tProjectId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.byProject(tProjectId)),
            data: tTaskJson,
            statusCode: 201,
          ));

      final result = await repository.createTask(tProjectId, 'Test Task', 'Desc', TaskStatus.todo, TaskPriority.high);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.title, 'Test Task'));
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(TaskEndpoints.byProject(tProjectId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.byProject(tProjectId)),
        message: 'Network Error',
      ));

      final result = await repository.createTask(tProjectId, 'Test Task', 'Desc', TaskStatus.todo, TaskPriority.high);
      expect(result.isLeft(), true);
    });
  });

  group('TaskRepositoryImp - update functions', () {
    const tProjectId = 'p1';
    const tTaskId = 't1';

    test('updateTaskStatus should return Right on success', () async {
      final updatedJson = {...tTaskJson, 'status': 'done'};
      when(() => mockDio.put('${TaskEndpoints.byProject(tProjectId)}/$tTaskId', data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${TaskEndpoints.byProject(tProjectId)}/$tTaskId'),
            data: updatedJson,
            statusCode: 200,
          ));

      final result = await repository.updateTaskStatus(tProjectId, tTaskId, TaskStatus.done);
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.status, TaskStatus.done));
    });

    test('updateTaskAssignee should return Right on success', () async {
      final updatedJson = {...tTaskJson, 'assigneeId': 'u3'};
      when(() => mockDio.put('${TaskEndpoints.byProject(tProjectId)}/$tTaskId', data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${TaskEndpoints.byProject(tProjectId)}/$tTaskId'),
            data: updatedJson,
            statusCode: 200,
          ));

      final result = await repository.updateTaskAssignee(tProjectId, tTaskId, 'u3');
      expect(result.isRight(), true);
    });

    test('updateTask should return Right on success', () async {
      final updatedJson = {...tTaskJson, 'title': 'Updated'};
      when(() => mockDio.put('${TaskEndpoints.byProject(tProjectId)}/$tTaskId', data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${TaskEndpoints.byProject(tProjectId)}/$tTaskId'),
            data: updatedJson,
            statusCode: 200,
          ));

      final result = await repository.updateTask(tProjectId, tTaskId, 'Updated', 'Desc', TaskPriority.low);
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.title, 'Updated'));
    });
    
    test('updateTaskStatus should return Left on failure', () async {
      when(() => mockDio.put('${TaskEndpoints.byProject(tProjectId)}/$tTaskId', data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: '${TaskEndpoints.byProject(tProjectId)}/$tTaskId'),
        message: 'Error',
      ));

      final result = await repository.updateTaskStatus(tProjectId, tTaskId, TaskStatus.done);
      expect(result.isLeft(), true);
    });
  });

  group('TaskRepositoryImp - deleteTask', () {
    const tProjectId = 'p1';
    const tTaskId = 't1';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(TaskEndpoints.delete(tProjectId, tTaskId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.delete(tProjectId, tTaskId)),
            statusCode: 200,
          ));

      final result = await repository.deleteTask(tProjectId, tTaskId);
      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(TaskEndpoints.delete(tProjectId, tTaskId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.delete(tProjectId, tTaskId)),
        message: 'Error',
      ));

      final result = await repository.deleteTask(tProjectId, tTaskId);
      expect(result.isLeft(), true);
    });
  });

  group('TaskRepositoryImp - dependencies', () {
    const tTaskId = 't1';

    test('getTaskDependencies should return Right on success', () async {
      final tDepsJson = [{'id': 'd1', 'taskId': 't1', 'predecessorTaskId': 't2', 'dependencyType': 'finishToStart'}];
      when(() => mockDio.get('${TaskEndpoints.byId(tTaskId)}/dependencies')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${TaskEndpoints.byId(tTaskId)}/dependencies'),
            data: tDepsJson,
            statusCode: 200,
          ));

      final result = await repository.getTaskDependencies(tTaskId);
      expect(result.isRight(), true);
    });

    test('setTaskDependency should return Right on success', () async {
      when(() => mockDio.post('${TaskEndpoints.byId(tTaskId)}/dependencies', data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${TaskEndpoints.byId(tTaskId)}/dependencies'),
            statusCode: 201,
          ));

      final result = await repository.setTaskDependency(tTaskId, 't2', 'finishToStart');
      expect(result.isRight(), true);
    });
  });
}
