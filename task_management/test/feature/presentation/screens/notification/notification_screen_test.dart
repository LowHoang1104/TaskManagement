import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/notification/notification_screen.dart';
import 'package:task_management/feature/presentation/providers/notification_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;

class MockNotificationNotifier extends StateNotifier<NotificationState> implements NotificationNotifier {
  MockNotificationNotifier(super.state);
  @override
  Future<void> fetchNotifications() async {}
  @override
  Future<void> markAsRead(String id) async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<bool> acceptProjectInvite(String projectId, String notificationId) async => true;
  @override
  Future<bool> declineProjectInvite(String projectId, String notificationId) async => true;
}

void main() {
  late MockNotificationNotifier mockNotificationNotifier;

  final tDate = DateTime.now().subtract(const Duration(hours: 1));
  final tNotif = NotificationEntity(id: '1', userId: 'u1', type: 'system', message: 'System message', isRead: false, createdAt: tDate);
  final tInvite = NotificationEntity(id: '2', userId: 'u1', type: 'invite', message: 'Invite message', isRead: false, relatedId: 'p1', createdAt: tDate);

  setUp(() {
    Animate.restartOnHotReload = false;
    mockNotificationNotifier = MockNotificationNotifier(NotificationState(notifications: [tNotif, tInvite]));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        notificationProvider.overrideWith((ref) => mockNotificationNotifier),
      ],
      child: const MaterialApp(
        home: NotificationScreen(),
      ),
    );
  }

  group('NotificationScreen Widget Tests', () {
    testWidgets('renders notifications correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('System message'), findsOneWidget);
      expect(find.text('Invite message'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('accepts invite when accept button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invitation accepted!'), findsOneWidget);
    });
  });
}
