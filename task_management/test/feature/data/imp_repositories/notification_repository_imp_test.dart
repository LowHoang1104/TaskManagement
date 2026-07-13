import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/notification_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late NotificationRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = NotificationRepositoryImp(mockDio);
  });

  group('NotificationRepositoryImp - getMyNotifications', () {
    final tNotificationsJson = [
      {
        'id': 'n1',
        'userId': 'u1',
        'type': 'Test Type',
        'message': 'Desc',
        'isRead': false,
        'createdAt': '2023-01-01T00:00:00.000Z',
      }
    ];

    test('should return Right(List<NotificationEntity>) on success', () async {
      when(() => mockDio.get(NotificationEndpoints.base)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: NotificationEndpoints.base),
            data: tNotificationsJson,
            statusCode: 200,
          ));

      final result = await repository.getMyNotifications();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'n1');
          expect(r.first.message, 'Desc');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(NotificationEndpoints.base)).thenThrow(DioException(
        requestOptions: RequestOptions(path: NotificationEndpoints.base),
        message: 'Network error',
      ));

      final result = await repository.getMyNotifications();

      expect(result.isLeft(), true);
    });
  });

  group('NotificationRepositoryImp - markAsRead', () {
    const tNotifId = 'n1';
    final tNotificationJson = {
      'id': tNotifId,
      'userId': 'u1',
      'type': 'Test Type',
      'message': 'Desc',
      'isRead': true,
      'createdAt': '2023-01-01T00:00:00.000Z',
    };

    test('should return Right(NotificationEntity) on success', () async {
      when(() => mockDio.put(NotificationEndpoints.markRead(tNotifId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: NotificationEndpoints.markRead(tNotifId)),
            data: tNotificationJson,
            statusCode: 200,
          ));

      final result = await repository.markAsRead(tNotifId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.id, tNotifId);
          expect(r.isRead, true);
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.put(NotificationEndpoints.markRead(tNotifId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: NotificationEndpoints.markRead(tNotifId)),
        message: 'Network error',
      ));

      final result = await repository.markAsRead(tNotifId);

      expect(result.isLeft(), true);
    });
  });
}
