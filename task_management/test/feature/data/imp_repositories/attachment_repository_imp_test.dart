import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/attachment_repository_imp.dart';

class MockDio extends Mock implements Dio {}
class MockFile extends Mock implements File {}

void main() {
  late AttachmentRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = AttachmentRepositoryImp(dio: mockDio);
  });

  group('AttachmentRepositoryImp - getAttachments', () {
    const tTaskId = 't1';
    final tAttachmentsJson = [
      {
        'id': 'a1',
        'taskId': tTaskId,
        'fileName': 'test.png',
        'fileUrl': 'http://url.com/test.png',
        'fileSize': 1024,
        'uploadedById': 'u1',
        'uploadedAt': '2023-01-01T00:00:00.000Z',
        'uploaderFullName': 'Test User',
      }
    ];

    test('should return Right(List<AttachmentEntity>) on success', () async {
      when(() => mockDio.get(TaskEndpoints.attachments(tTaskId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.attachments(tTaskId)),
            data: tAttachmentsJson,
            statusCode: 200,
          ));

      final result = await repository.getAttachments(tTaskId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'a1');
          expect(r.first.fileName, 'test.png');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(TaskEndpoints.attachments(tTaskId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.attachments(tTaskId)),
        message: 'Network error',
      ));

      final result = await repository.getAttachments(tTaskId);

      expect(result.isLeft(), true);
    });
  });

  group('AttachmentRepositoryImp - uploadAttachment', () {
    const tTaskId = 't1';
    late File tFile;
    
    setUpAll(() async {
      registerFallbackValue(FormData.fromMap({}));
      tFile = File('test_attachment.png');
      await tFile.writeAsBytes([0]);
    });

    tearDownAll(() async {
      if (await tFile.exists()) {
        await tFile.delete();
      }
    });

    test('should return Right(AttachmentEntity) on success', () async {
      when(() => mockDio.post(TaskEndpoints.attachments(tTaskId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: TaskEndpoints.attachments(tTaskId)),
            data: {
              'id': 'a2',
              'taskId': tTaskId,
              'fileName': 'test_attachment.png',
              'fileUrl': 'http://url.com/test_attachment.png',
              'fileSize': 1,
              'uploadedById': 'u1',
              'uploadedAt': '2023-01-01T00:00:00.000Z',
              'uploaderFullName': 'Test User',
            },
            statusCode: 201,
          ));

      final result = await repository.uploadAttachment(tTaskId, tFile);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left: $l'),
        (r) {
          expect(r.id, 'a2');
          expect(r.fileName, 'test_attachment.png');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(TaskEndpoints.attachments(tTaskId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: TaskEndpoints.attachments(tTaskId)),
        message: 'Upload failed',
      ));

      final result = await repository.uploadAttachment(tTaskId, tFile);

      expect(result.isLeft(), true);
    });
  });
}
