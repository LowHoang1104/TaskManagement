import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_management/feature/presentation/providers/task_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/notification_provider.dart';
import 'package:task_management/feature/presentation/providers/project_members_provider.dart';
import 'package:task_management/feature/presentation/providers/task_dependencies_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/feature/presentation/screens/task/task_board_screen.dart';
import 'package:task_management/app/routes/app_routes.dart';

class MockTaskNotifier extends StateNotifier<TaskState> implements TaskNotifier {
  MockTaskNotifier(super.state);
  @override
  String get projectId => 'p1';
  @override
  Future<void> fetchTasks() async {}
  @override
  Future<TaskEntity?> createTask(String title, String description, TaskStatus status, TaskPriority priority) async => null;
  @override
  Future<bool> updateTaskStatusLocally(String taskId, TaskStatus newStatus) async => true;
  @override
  Future<void> updateTaskAssignee(String taskId, String? assigneeId) async {}
  @override
  void updateTaskAssigneeLocally(TaskEntity updatedTask) {}
  @override
  Future<bool> deleteTask(String id) async => true;
  @override
  void handleTaskUpdateEvent(TaskEntity task) {}
  @override
  void dispose() { super.dispose(); }
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  Future<bool> login(String email, String password) async => true;
  @override
  Future<bool> register(String fullName, String email, String password) async => true;
  @override Future<void> logout() async {}
  @override Future<void> checkAuthStatus() async {}
  @override Future<bool> changePassword(String c, String n) async => true;
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

class MockProjectMembersNotifier extends StateNotifier<ProjectMembersState> implements ProjectMembersNotifier {
  MockProjectMembersNotifier(super.state);
  @override
  String get projectId => 'p1';
  @override
  Future<void> fetchMembers() async {}
  @override
  Future<bool> inviteMember(String email) async => true;
  @override
  Future<bool> updateRole(String userId, String newRole) async => true;
  @override
  Future<bool> assignRole(String userId, String role) async => true;
  @override
  Future<bool> removeMember(String userId) async => true;
}

class MockTaskDependenciesNotifier extends StateNotifier<TaskDependenciesState> implements TaskDependenciesNotifier {
  MockTaskDependenciesNotifier(super.state);
  @override
  String get taskId => 't1-00000';
  @override
  Future<void> fetchDependencies() async {}
  @override
  Future<bool> setDependency(String predecessorId, String type) async => true;
}

void main() {
  late MockTaskNotifier mockTaskNotifier;
  late MockAuthNotifier mockAuthNotifier;
  late MockNotificationNotifier mockNotificationNotifier;
  late MockProjectMembersNotifier mockProjectMembersNotifier;

  const tProjectId = 'p1';
  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tTask = TaskEntity(id: 't1-00000', title: 'Task 1', description: 'Desc 1', projectId: tProjectId, status: TaskStatus.todo, priority: TaskPriority.high, reporterId: 'u1', assigneeId: 'u1', order: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), dependencies: const []);

  setUp(() {
    Animate.restartOnHotReload = false;
    
    mockTaskNotifier = MockTaskNotifier(TaskState(tasks: [tTask]));
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
    final unreadNotif = NotificationEntity(id: '1', userId: 'u1', type: 'system', message: 'm', isRead: false, createdAt: DateTime.now());
    mockNotificationNotifier = MockNotificationNotifier(NotificationState(notifications: [unreadNotif, unreadNotif]));
    mockProjectMembersNotifier = MockProjectMembersNotifier(ProjectMembersState(members: [tUser]));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        taskNotifierProvider(tProjectId).overrideWith((ref) => mockTaskNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
        notificationProvider.overrideWith((ref) => mockNotificationNotifier),
        projectMembersProvider(tProjectId).overrideWith((ref) => mockProjectMembersNotifier),
        taskDependenciesProvider('t1-00000').overrideWith((ref) => MockTaskDependenciesNotifier(TaskDependenciesState())),
      ],
      child: MaterialApp(
        home: const TaskBoardScreen(
          projectId: tProjectId, 
          projectName: 'My Project', 
          workspaceName: 'My Workspace', 
          workspaceId: 'w1'
        ),
        routes: {
          AppRoutes.taskDetail: (_) => const Scaffold(body: Text('TaskDetailScreen')),
          AppRoutes.projectMembers: (_) => const Scaffold(body: Text('ProjectMembersScreen')),
        },
      ),
    );
  }

  group('TaskBoardScreen Widget Tests', () {
    testWidgets('renders task board correctly with columns and tasks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('My Project'), findsOneWidget);
      expect(find.text('My Workspace'), findsOneWidget);
      expect(find.text('CẦN LÀM'), findsOneWidget);
      expect(find.text('ĐANG TIẾN HÀNH'), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);
      
      // Unread notification badge
      expect(find.text('2'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('navigates to task detail when task is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task 1'));
      await tester.pumpAndSettle();

      expect(find.text('TaskDetailScreen'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
    
    testWidgets('navigates to project members when members icon is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.people_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ProjectMembersScreen'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
