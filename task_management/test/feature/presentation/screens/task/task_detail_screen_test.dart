import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_management/feature/presentation/providers/task_detail_provider.dart';
import 'package:task_management/feature/presentation/providers/task_provider.dart';
import 'package:task_management/feature/presentation/providers/task_dependencies_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/project_members_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/feature/presentation/screens/task/task_detail_screen.dart';
import 'dart:io';

class MockTaskDetailNotifier extends StateNotifier<TaskDetailState> implements TaskDetailNotifier {
  MockTaskDetailNotifier(super.state);
  @override
  TaskEntity get task => state.task;
  @override
  String get projectId => 'p1';
  @override
  String get taskId => 't1-00000';
  @override
  Future<void> fetchDetails() async {}
  @override
  Future<void> updateTaskAssignee(String? newAssigneeId, WidgetRef ref) async {}
  @override
  Future<void> updateTask(TaskEntity updatedTask) async {}
  @override
  Future<void> addComment(String content) async {}
  @override
  Future<void> uploadAttachment(File file) async {}
}

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

class MockTaskDependenciesNotifier extends StateNotifier<TaskDependenciesState> implements TaskDependenciesNotifier {
  MockTaskDependenciesNotifier(super.state);
  @override
  String get taskId => 't1-00000';
  @override
  Future<void> fetchDependencies() async {}
  @override
  Future<bool> setDependency(String predecessorId, String type) async => true;
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
  @override Future<bool> uploadAvatar({required String fileName, required List<int> fileBytes}) async => true;
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

void main() {
  late MockTaskDetailNotifier mockTaskDetailNotifier;
  late MockTaskNotifier mockTaskNotifier;
  late MockTaskDependenciesNotifier mockTaskDependenciesNotifier;
  late MockAuthNotifier mockAuthNotifier;
  late MockProjectMembersNotifier mockProjectMembersNotifier;

  const tProjectId = 'p1';
  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', role: 'Owner', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tTask = TaskEntity(id: 't1-00000', title: 'Task 1', description: 'Desc 1', projectId: tProjectId, status: TaskStatus.todo, priority: TaskPriority.high, reporterId: 'u1', assigneeId: 'u1', assigneeName: 'Test User', reporterName: 'Test User', order: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), dependencies: const []);
  final tComment = CommentEntity(id: 'c1', taskId: 't1-00000', userId: 'u1', userFullName: 'Test User', content: 'This is a comment', createdAt: DateTime.now());

  setUp(() {
    Animate.restartOnHotReload = false;
    
    mockTaskDetailNotifier = MockTaskDetailNotifier(TaskDetailState(task: tTask, comments: [tComment], attachments: []));
    mockTaskNotifier = MockTaskNotifier(TaskState(tasks: [tTask]));
    mockTaskDependenciesNotifier = MockTaskDependenciesNotifier(TaskDependenciesState());
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
    mockProjectMembersNotifier = MockProjectMembersNotifier(ProjectMembersState(members: [tUser]));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        taskDetailProvider(tTask).overrideWith((ref) => mockTaskDetailNotifier),
        taskNotifierProvider(tProjectId).overrideWith((ref) => mockTaskNotifier),
        taskDependenciesProvider(tTask.id).overrideWith((ref) => mockTaskDependenciesNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
        projectMembersProvider(tProjectId).overrideWith((ref) => mockProjectMembersNotifier),
      ],
      child: MaterialApp(
        home: TaskDetailScreen(task: tTask),
      ),
    );
  }

  group('TaskDetailScreen Widget Tests', () {
    testWidgets('renders task details correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Desc 1'), findsOneWidget);
      expect(find.text('Test User'), findsWidgets); // Assignee and reporter
      expect(find.text('HIGH'), findsOneWidget); // Priority
      
      // Comments
      expect(find.text('This is a comment'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('shows assign dialog when assignee is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final assigneeFinder = find.text('Test User').first;
      await tester.tap(assigneeFinder);
      await tester.pumpAndSettle();

      expect(find.text('Assign Task'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
