import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/core/di/injection_container.dart';
import 'package:task_management/feature/application/i_services/i_notification_service.dart';
import 'package:task_management/feature/application/i_services/i_project_service.dart';
import 'package:task_management/feature/domain/entities/notification_entity.dart';
import 'package:task_management/feature/presentation/providers/notification_provider.dart';

class MockNotificationService extends Mock implements INotificationService {}
class MockProjectService extends Mock implements IProjectService {}

void main() {
  late NotificationNotifier notifier;
  late MockNotificationService mockNotificationService;
  late MockProjectService mockProjectService;

  final tNotification = NotificationEntity(
    id: 'n1',
    userId: 'u1',
    type: 'project_invite',
    message: 'Test message',
    isRead: false,
    relatedId: 'p1',
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    mockNotificationService = MockNotificationService();
    mockProjectService = MockProjectService();
    sl.registerLazySingleton<INotificationService>(() => mockNotificationService);
    sl.registerLazySingleton<IProjectService>(() => mockProjectService);
  });

  setUp(() {
    // Stub fetch in constructor
    when(() => mockNotificationService.getMyNotifications())
        .thenAnswer((_) async => Right([tNotification]));
    
    notifier = NotificationNotifier();
  });

  tearDownAll(() {
    sl.reset();
  });

  group('NotificationNotifier - fetchNotifications', () {
    test('should set notifications and update unread count on success', () async {
      await Future.delayed(Duration.zero);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.notifications.length, 1);
      expect(notifier.state.unreadCount, 1);
    });

    test('should set error on fetch failure', () async {
      when(() => mockNotificationService.getMyNotifications())
          .thenAnswer((_) async => const Left('Fetch Error'));
      notifier = NotificationNotifier();
      
      await Future.delayed(Duration.zero);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
    });
  });

  group('NotificationNotifier - markAsRead', () {
    test('should update isRead status locally on success', () async {
      final readNotif = tNotification.copyWith(isRead: true);
      when(() => mockNotificationService.markAsRead('n1'))
          .thenAnswer((_) async => Right(readNotif));

      await Future.delayed(Duration.zero);
      await notifier.markAsRead('n1');

      expect(notifier.state.notifications.first.isRead, true);
      expect(notifier.state.unreadCount, 0);
    });
  });

  group('NotificationNotifier - acceptProjectInvite', () {
    test('should accept invite and mark as read on success', () async {
      when(() => mockProjectService.acceptProjectInvitation('p1'))
          .thenAnswer((_) async => const Right(true));
      final readNotif = tNotification.copyWith(isRead: true);
      when(() => mockNotificationService.markAsRead('n1'))
          .thenAnswer((_) async => Right(readNotif));

      await Future.delayed(Duration.zero);
      final result = await notifier.acceptProjectInvite('p1', 'n1');

      expect(result, true);
      expect(notifier.state.notifications.first.isRead, true);
    });

    test('should return false on accept failure', () async {
      when(() => mockProjectService.acceptProjectInvitation('p1'))
          .thenAnswer((_) async => const Left('Accept Error'));

      await Future.delayed(Duration.zero);
      final result = await notifier.acceptProjectInvite('p1', 'n1');

      expect(result, false);
      expect(notifier.state.error, 'Accept Error');
    });
  });
}
