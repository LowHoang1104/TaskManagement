import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/attachment_repository_imp.dart';

class MockDio extends Mock implements Dio {}
class FakeFile extends Fake implements File {
  @override
  String get path => '/path/to/test.png';
}
class FakeFormData extends Fake implements FormData {}

void main() {
  late MockDio mockDio;
  late AttachmentRepositoryImp repository;

  setUpAll(() {
    registerFallbackValue(FakeFormData());
  });

  setUp(() {
    mockDio = MockDio();
    repository = AttachmentRepositoryImp(dio: mockDio);
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

  Map<String, dynamic> sampleAttachmentJson({String id = '1'}) => {
        'id': id,
        'taskId': 't1',
        'fileName': 'test.png',
        'fileUrl': 'http://example.com/test.png',
        'fileSize': 1024,
        'uploadedById': 'u1',
        'uploadedAt': '2024-01-01T00:00:00.000Z',
        'uploaderFullName': 'Jane Doe',
      };

  group('getAttachments', () {
    test('returns Right(List<AttachmentEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.attachments('t1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.attachments('t1')),
          statusCode: 200,
          data: [sampleAttachmentJson()],
        ),
      );

      final result = await repository.getAttachments('t1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (attachments) {
          expect(attachments.length, 1);
          expect(attachments.first.id, '1');
          expect(attachments.first.fileName, 'test.png');
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.get(TaskEndpoints.attachments('t1')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Bad request'}));

      final result = await repository.getAttachments('t1');

      expect(result, const Left('Bad request'));
    });
  });

  group('uploadAttachmentBytes', () {
    test('returns Right(AttachmentEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.attachments('t1'), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.attachments('t1')),
          statusCode: 201,
          data: sampleAttachmentJson(),
        ),
      );

      final result = await repository.uploadAttachmentBytes('t1', 'test.png', [1, 2, 3]);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('expected Right, got Left($l)'),
        (attachment) {
          expect(attachment.id, '1');
          expect(attachment.fileName, 'test.png');
        },
      );
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.post(TaskEndpoints.attachments('t1'), data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 400, data: {'message': 'Upload failed'}));

      final result = await repository.uploadAttachmentBytes('t1', 'test.png', [1, 2, 3]);

      expect(result, const Left('Upload failed'));
    });
  });

  group('deleteAttachment', () {
    test('returns Right(true) on success', () async {
      when(() => mockDio.delete(TaskEndpoints.attachmentById('t1', 'a1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: TaskEndpoints.attachmentById('t1', 'a1')),
          statusCode: 200,
        ),
      );

      final result = await repository.deleteAttachment('t1', 'a1');

      expect(result, const Right(true));
    });

    test('returns Left(message) on DioException', () async {
      when(() => mockDio.delete(TaskEndpoints.attachmentById('t1', 'a1')))
          .thenThrow(dioError(statusCode: 404, data: {'message': 'Not found'}));

      final result = await repository.deleteAttachment('t1', 'a1');

      expect(result, const Left('Not found'));
    });
  });
}