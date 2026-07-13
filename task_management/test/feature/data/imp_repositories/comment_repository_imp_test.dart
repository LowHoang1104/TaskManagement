import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/comment_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late CommentRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = CommentRepositoryImp(dio: mockDio);
  });

  group('CommentRepositoryImp - getComments', () {
    const tTaskId = 't1';
    final tCommentsJson = [
      {
        'id': 'c1',
        'taskId': tTaskId,
        'userId': 'u1',
        'content': 'Hello',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'userFullName': 'User 1',
        'userAvatarUrl': null,
      }
    ];

    test('should return Right(List<CommentEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.comments(tTaskId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.comments(tTaskId)),
            data: tCommentsJson,
            statusCode: 200,
          ));

      final result = await repository.getComments(tTaskId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'c1');
          expect(r.first.content, 'Hello');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(TaskEndpoints.comments(tTaskId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.comments(tTaskId)),
        message: 'Network error',
      ));

      final result = await repository.getComments(tTaskId);

      expect(result.isLeft(), true);
    });
  });

  group('CommentRepositoryImp - createComment', () {
    const tTaskId = 't1';
    const tContent = 'New comment';
    final tCommentJson = {
      'id': 'c2',
      'taskId': tTaskId,
      'userId': 'u1',
      'content': tContent,
      'createdAt': '2023-01-01T00:00:00.000Z',
      'userFullName': 'User 1',
    };

    test('should return Right(CommentEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.comments(tTaskId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.comments(tTaskId)),
            data: tCommentJson,
            statusCode: 201,
          ));

      final result = await repository.createComment(tTaskId, tContent);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.id, 'c2');
          expect(r.content, tContent);
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(TaskEndpoints.comments(tTaskId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.comments(tTaskId)),
        message: 'Network error',
      ));

      final result = await repository.createComment(tTaskId, tContent);

      expect(result.isLeft(), true);
    });
  });
}
