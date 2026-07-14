import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/workspace/workspace_list_screen.dart';
import 'package:task_management/feature/presentation/providers/workspace_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/notification_provider.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/app/routes/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MockWorkspaceNotifier extends StateNotifier<WorkspaceState> implements WorkspaceNotifier {
  MockWorkspaceNotifier(super.state);
  @override
  Future<void> fetchWorkspaces() async {}
  @override
  Future<void> createWorkspace(String name, String description) async {}
  @override
  Future<bool> deleteWorkspace(String id) async => true;
  @override
  Future<bool> updateWorkspace(String id, String name, String description) async => true;
  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async => null;
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  Future<bool> login(String email, String password) async => true;
  @override Future<bool> register(String fullName, String email, String password) async => true;
  @override Future<void> logout() async {}
  @override Future<void> checkAuthStatus() async {}
  @override Future<bool> changePassword(String c, String n) async => true;
  @override Future<bool> uploadAvatar({required String fileName, required List<int> fileBytes}) async => true;
}

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

class MockWorkspaceMembersNotifier extends StateNotifier<WorkspaceMembersState> implements WorkspaceMembersNotifier {
  MockWorkspaceMembersNotifier(super.state);
  @override
  String get workspaceId => 'ws1';
  @override
  Future<void> fetchMembers() async {}
  @override
  Future<bool> inviteMember(String email) async => true;
  @override
  Future<bool> removeMember(String memberId) async => true;
  @override
  Future<bool> updateRole(String memberId, String role) async => true;
}

void main() {
  late MockWorkspaceNotifier mockWorkspaceNotifier;
  late MockAuthNotifier mockAuthNotifier;
  late MockNotificationNotifier mockNotificationNotifier;

  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tWorkspace = WorkspaceEntity(id: 'ws1', name: 'Test Workspace', description: 'Test Desc', ownerId: 'u1', createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUp(() {
    Animate.restartOnHotReload = false;
    mockWorkspaceNotifier = MockWorkspaceNotifier(WorkspaceState(workspaces: [tWorkspace]));
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
    mockNotificationNotifier = MockNotificationNotifier(const NotificationState(notifications: []));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        workspaceNotifierProvider.overrideWith((ref) => mockWorkspaceNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
        notificationProvider.overrideWith((ref) => mockNotificationNotifier),
        workspaceMembersProvider('ws1').overrideWith((ref) => MockWorkspaceMembersNotifier(const WorkspaceMembersState(members: []))),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.projectDetail) {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Project Detail')));
          }
          if (settings.name == AppRoutes.workspaceMembers) {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Workspace Members')));
          }
          return null;
        },
        home: const WorkspaceListScreen(),
      ),
    );
  }

  group('WorkspaceListScreen Widget Tests', () {
    testWidgets('renders workspace list correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Your Workspaces'), findsOneWidget);
      expect(find.text('Test Workspace'), findsOneWidget);
      expect(find.text('Create New'), findsOneWidget);
    });

    testWidgets('shows create workspace dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New'));
      await tester.pumpAndSettle();

      expect(find.text('New Workspace'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'New WS');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows popup menu and handles navigation', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      expect(find.text('Workspace Members'), findsOneWidget);
    });
  });
}
