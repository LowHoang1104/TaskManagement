import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_management/feature/presentation/providers/project_provider.dart';
import 'package:task_management/feature/presentation/providers/workspace_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';
import 'package:task_management/feature/domain/entities/workspace_entity.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/domain/entities/project_entity.dart';
import 'package:task_management/feature/presentation/screens/workspace/project_dashboard_screen.dart';
import 'package:task_management/app/routes/app_routes.dart';
import '../../../../helpers/pump_app.dart';

class MockProjectNotifier extends StateNotifier<ProjectState> implements ProjectNotifier {
  MockProjectNotifier(super.state);
  @override
  Future<void> fetchProjects(String workspaceId) async {}
  @override
  Future<bool> createProject(String workspaceId, String name, String description) async => true;
  @override
  Future<bool> deleteProject(String workspaceId, String id) async => true;
  @override
  Future<bool> leaveProject(String projectId) async => true;
}

class MockWorkspaceNotifier extends StateNotifier<WorkspaceState> implements WorkspaceNotifier {
  MockWorkspaceNotifier(super.state);
  @override
  Future<void> fetchWorkspaces() async {}
  @override
  Future<bool> createWorkspace(String name, String description) async => true;
  @override
  Future<bool> deleteWorkspace(String id) async => true;
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

class MockWorkspaceMembersNotifier extends StateNotifier<WorkspaceMembersState> implements WorkspaceMembersNotifier {
  MockWorkspaceMembersNotifier(super.state);
  @override
  String get workspaceId => 'w1';
  @override
  Future<void> fetchMembers() async {}
  @override
  Future<bool> inviteMember(String email) async => true;
  @override
  Future<bool> updateRole(String userId, String newRole) async => true;
  @override
  Future<bool> removeMember(String userId) async => true;
}

void main() {
  late MockProjectNotifier mockProjectNotifier;
  late MockWorkspaceNotifier mockWorkspaceNotifier;
  late MockAuthNotifier mockAuthNotifier;
  late MockWorkspaceMembersNotifier mockWorkspaceMembersNotifier;

  const tWorkspaceId = 'w1';
  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', createdAt: DateTime.now(), updatedAt: DateTime.now(), role: 'Owner');
  final tWorkspace = WorkspaceEntity(id: tWorkspaceId, name: 'My Workspace', description: 'Desc', ownerId: 'u1', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tProject = ProjectEntity(id: 'p1', name: 'Project 1', description: 'Proj Desc', workspaceId: tWorkspaceId, ownerId: 'u1', progress: 50, createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUp(() {
    Animate.restartOnHotReload = false;
    
    mockProjectNotifier = MockProjectNotifier(ProjectState(projects: [tProject]));
    mockWorkspaceNotifier = MockWorkspaceNotifier(WorkspaceState(workspaces: [tWorkspace]));
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
    mockWorkspaceMembersNotifier = MockWorkspaceMembersNotifier(WorkspaceMembersState(members: [tUser]));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        projectNotifierProvider.overrideWith((ref, arg) => mockProjectNotifier),
        workspaceNotifierProvider.overrideWith((ref) => mockWorkspaceNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
        workspaceMembersProvider.overrideWith((ref, arg) => mockWorkspaceMembersNotifier),
      ],
      child: MaterialApp(
        home: const ProjectDashboardScreen(workspaceId: tWorkspaceId),
        routes: {
          AppRoutes.taskBoard: (_) => const Scaffold(body: Text('TaskBoardScreen')),
          AppRoutes.workspaceMembers: (_) => const Scaffold(body: Text('WorkspaceMembersScreen')),
          AppRoutes.workspaceList: (_) => const Scaffold(body: Text('WorkspaceListScreen')),
        },
      ),
    );
  }

  group('ProjectDashboardScreen Widget Tests', () {
    testWidgets('renders dashboard correctly with project data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('My Workspace'), findsOneWidget);
      expect(find.text('Project Dashboard'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Stat value
      expect(find.text('Project 1'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('navigates to task board when project is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Project 1'));
      await tester.pumpAndSettle();

      expect(find.text('TaskBoardScreen'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
