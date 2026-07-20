import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:task_management/core/di/injection_container.dart';
import 'package:task_management/feature/application/i_services/i_notification_service.dart';
import 'package:task_management/feature/application/i_services/i_project_service.dart';
import 'package:task_management/feature/application/i_services/i_workspace_service.dart';
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';
import 'package:task_management/feature/domain/entities/notification_entity.dart';
import 'package:task_management/feature/presentation/providers/notification_provider.dart';

class MockSignalRService extends Mock implements SignalRService {}

class MockNotificationService extends Mock implements INotificationService {}

class MockWorkspaceService extends Mock implements IWorkspaceService {}

class MockProjectService extends Mock implements IProjectService {}

void main() {
  late MockSignalRService mockSignalRService;
  late MockNotificationService mockNotificationService;
  late MockWorkspaceService mockWorkspaceService;
  late MockProjectService mockProjectService;

  late StreamController<String> signalRStreamController;
  late List<NotificationEntity> tNotificationList;
  late NotificationEntity tNotification;
  late NotificationEntity tNotificationRead;

  setUp(() async {
    // Reset GetIt completely to prevent leaky configurations between tests
    await GetIt.I.reset();

    mockSignalRService = MockSignalRService();
    mockNotificationService = MockNotificationService();
    mockWorkspaceService = MockWorkspaceService();
    mockProjectService = MockProjectService();

    signalRStreamController = StreamController<String>.broadcast();

    tNotification = NotificationEntity(
      id: '1',
      userId: 'user_1',
      type: 'Invite',
      message: 'You have been invited!',
      isRead: false,
      relatedId: 'target_id',
      createdAt: DateTime.now(),
    );

    tNotificationRead = tNotification.copyWith(isRead: true);
    tNotificationList = [tNotification];

    // Setup base stubs for dependencies invoked on construction
    when(
      () => mockSignalRService.notificationStream,
    ).thenAnswer((_) => signalRStreamController.stream);
    when(
      () => mockNotificationService.getMyNotifications(),
    ).thenAnswer((_) async => Right(tNotificationList));

    // Register mocks into your global Service Locator instance
    sl.registerSingleton<SignalRService>(mockSignalRService);
    sl.registerSingleton<INotificationService>(mockNotificationService);
    sl.registerSingleton<IWorkspaceService>(mockWorkspaceService);
    sl.registerSingleton<IProjectService>(mockProjectService);
  });

  tearDown(() async {
    await signalRStreamController.close();
  });

  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('NotificationNotifier Initialization & Stream', () {
    test(
      'initial state fetches notifications and correctly sets unreadCount',
      () async {
        final container = makeProviderContainer();

        // Let initialization async actions fire
        await container
            .read(notificationProvider.notifier)
            .fetchNotifications();

        final state = container.read(notificationProvider);
        expect(state.isLoading, false);
        expect(state.notifications, tNotificationList);
        expect(state.unreadCount, 1);
      },
    );

    group('Notification Actions', () {
      test(
        'markAsRead should update the targeted notification state',
        () async {
          when(
            () => mockNotificationService.markAsRead('1'),
          ).thenAnswer((_) async => Right(tNotificationRead));

          final container = makeProviderContainer();
          await container
              .read(notificationProvider.notifier)
              .fetchNotifications(); // loads tNotification

          await container.read(notificationProvider.notifier).markAsRead('1');

          final state = container.read(notificationProvider);
          expect(state.notifications.first.isRead, true);
          expect(state.unreadCount, 0);
        },
      );
      test('declineWorkspaceInvite handles failure scenario cleanly', () async {
        when(
          () => mockWorkspaceService.declineWorkspaceInvite('ws_1'),
        ).thenAnswer((_) async => const Left('Failed to reject workspace'));

        final container = makeProviderContainer();
        await container
            .read(notificationProvider.notifier)
            .fetchNotifications();

        final result = await container
            .read(notificationProvider.notifier)
            .declineWorkspaceInvite('ws_1', '1');

        expect(result, false);
        final state = container.read(notificationProvider);
        expect(state.isLoading, false);
        expect(state.error, 'Failed to reject workspace');
      });
      test('declineProjectInvite handles failure scenario cleanly', () async {
        when(
          () => mockProjectService.declineProjectInvitation('proj_1'),
        ).thenAnswer((_) async => const Left('Failed to reject project'));

        final container = makeProviderContainer();
        await container
            .read(notificationProvider.notifier)
            .fetchNotifications();

        final result = await container
            .read(notificationProvider.notifier)
            .declineProjectInvite('proj_1', '1');

        expect(result, false);
        final state = container.read(notificationProvider);
        expect(state.isLoading, false);
        expect(state.error, 'Failed to reject project');
      });
    });
  });
}
