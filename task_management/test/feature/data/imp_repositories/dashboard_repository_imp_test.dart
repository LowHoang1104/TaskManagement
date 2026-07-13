import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/dashboard_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late DashboardRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = DashboardRepositoryImp(mockDio);
  });

  group('DashboardRepositoryImp - getDashboardStats', () {
    final tStatsJson = {
      'totalTasksDone': 15,
      'totalTasksOngoing': 13,
      'tasksToDo': 10,
      'tasksInProgress': 3,
      'tasksReview': 0,
    };

    test('should return Right(DashboardEntity) on success', () async {
      when(() => mockDio.get(UserEndpoints.dashboard)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: UserEndpoints.dashboard),
            data: tStatsJson,
            statusCode: 200,
          ));

      final result = await repository.getDashboardStats();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.totalTasksDone, 15);
          expect(r.tasksToDo, 10);
        },
      );
    });

    test('should return Left with error message on failure', () async {
      when(() => mockDio.get(UserEndpoints.dashboard)).thenThrow(DioException(
        requestOptions: RequestOptions(path: UserEndpoints.dashboard),
        response: Response(requestOptions: RequestOptions(path: UserEndpoints.dashboard), data: {'message': 'Server Error'}, statusCode: 500),
      ));

      final result = await repository.getDashboardStats();

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Server Error'),
        (r) => fail('Should not return right'),
      );
    });

    test('should return Left with generic network error on network exception', () async {
      when(() => mockDio.get(UserEndpoints.dashboard)).thenThrow(DioException(
        requestOptions: RequestOptions(path: UserEndpoints.dashboard),
        message: 'Network error',
      ));

      final result = await repository.getDashboardStats();

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Network error'),
        (r) => fail('Should not return right'),
      );
    });
  });
}
