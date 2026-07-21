import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/task_repository_imp.dart';
import 'package:task_management/feature/domain/entities/enums.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late TaskRepositoryImp repository;

  setUp(() {
    mockDio = MockDio();
    repository = TaskRepositoryImp(dio: mockDio);
  });

  DioException dioError({int? statusCode, dynamic data, String? message}) {
    final requestOptions = RequestOptions(path: '/');
    return DioException(
      requestOptions: requestOptions,
      response: statusCode != null
          ? Response(requestOptions: requestOptions, statusCode: statusCode, data: data)
          : null,
      message: message,
    );
  }

  Map<String, dynamic> sampleTaskJson({String id = '1'}) => {
        'id': id,
        'projectId': 'p1',
        'title': 'Test Task',
        'description': 'Description here',
        'status': 'todo',
        'priority': 'high',
        'assigneeId': 'u1',
        'reporterId': 'u2',
        'assigneeName': 'Jane',
        'reporterName': 'John',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'relations': []
      };

  group('getTasks', () {
    test('returns Right(List<TaskEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.byProject('p1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.byProject('p1')),
          statusCode: 200,
          data: [sampleTaskJson()],
        ),
      );

      final result = await repository.getTasks('p1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.id, '1');
          expect(tasks.first.title, 'Test Task');
          expect(tasks.first.status, TaskStatus.todo);
          expect(tasks.first.priority, TaskPriority.high);
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.get(TaskEndpoints.byProject('p1')))
          .thenThrow(dioError(statusCode: 500, data: {'message': 'Server error'}));

      final result = await repository.getTasks('p1');

      expect(result, const Left('Server error'));
    });
  });

  group('createTask', () {
    test('returns Right(TaskEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.byProject('p1'), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.byProject('p1')),
          statusCode: 201,
          data: sampleTaskJson(),
        ),
      );

      final result = await repository.createTask('p1', 'Test Task', 'Description here', TaskStatus.todo, TaskPriority.high);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (task) {
          expect(task.id, '1');
          expect(task.title, 'Test Task');
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.post(TaskEndpoints.byProject('p1'), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Bad request'}));

      final result = await repository.createTask('p1', 'Test Task', '', TaskStatus.todo, TaskPriority.low);

      expect(result, const Left('Bad request'));
    });
  });

  group('updateTaskStatus', () {
    test('returns Right(TaskEntity) on success', () async {
      when(() => mockDio.put('${TaskEndpoints.byProject('p1')}/1', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '${TaskEndpoints.byProject('p1')}/1'),
          statusCode: 200,
          data: sampleTaskJson()..['status'] = 'doing',
        ),
      );

      final result = await repository.updateTaskStatus('p1', '1', TaskStatus.doing);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should return Right'),
        (task) {
          expect(task.id, '1');
          expect(task.status, TaskStatus.doing);
        },
      );
    });
  });

  group('deleteTask', () {
    test('returns Right(true) on success', () async {
      when(() => mockDio.delete(TaskEndpoints.delete('p1', '1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.delete('p1', '1')),
          statusCode: 200,
        ),
      );

      final result = await repository.deleteTask('p1', '1');

      expect(result, const Right(true));
    });
  });
}