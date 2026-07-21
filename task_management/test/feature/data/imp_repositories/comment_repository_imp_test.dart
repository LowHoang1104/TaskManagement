import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/comment_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late CommentRepositoryImp repository;

  setUp(() {
    mockDio = MockDio();
    repository = CommentRepositoryImp(dio: mockDio);
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

  Map<String, dynamic> sampleCommentJson({String id = '1'}) => {
        'id': id,
        'taskId': 't1',
        'userId': 'u1',
        'content': 'This is a test comment',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'userFullName': 'Jane Doe',
        'userAvatarUrl': 'http://avatar.com/1.png',
      };

  group('getComments', () {
    test('returns Right(List<CommentEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.comments('t1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.comments('t1')),
          statusCode: 200,
          data: [sampleCommentJson()],
        ),
      );

      final result = await repository.getComments('t1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (comments) {
          expect(comments.length, 1);
          expect(comments.first.id, '1');
          expect(comments.first.content, 'This is a test comment');
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.get(TaskEndpoints.comments('t1')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Bad request'}));

      final result = await repository.getComments('t1');

      expect(result, const Left('Bad request'));
    });

    test('returns Left(error) on generic Exception', () async {
      when(() => mockDio.get(TaskEndpoints.comments('t1'))).thenThrow(Exception('Server error'));

      final result = await repository.getComments('t1');

      expect(result.isLeft(), true);
    });
  });

  group('createComment', () {
    test('returns Right(CommentEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.comments('t1'), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.comments('t1')),
          statusCode: 201,
          data: sampleCommentJson(),
        ),
      );

      final result = await repository.createComment('t1', 'This is a test comment');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (comment) {
          expect(comment.id, '1');
          expect(comment.content, 'This is a test comment');
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.post(TaskEndpoints.comments('t1'), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Failed to create comment'}));

      final result = await repository.createComment('t1', 'This is a test comment');

      expect(result, const Left('Failed to create comment'));
    });
  });
}