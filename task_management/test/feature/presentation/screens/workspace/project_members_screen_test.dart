import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/project/project_members_screen.dart';
import 'package:task_management/feature/presentation/providers/project_members_provider.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MockProjectMembersNotifier extends StateNotifier<ProjectMembersState> implements ProjectMembersNotifier {
  MockProjectMembersNotifier(super.state);
  @override
  String get projectId => 'p1';
  @override
  Future<void> fetchMembers() async {}
  @override
  Future<bool> inviteMember(String email) async => true;
  @override
  Future<bool> removeMember(String memberId) async => true;
  @override
  Future<bool> updateRole(String memberId, String role) async => true;
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

void main() {
  late MockProjectMembersNotifier mockProjectMembersNotifier;
  late MockWorkspaceMembersNotifier mockWorkspaceMembersNotifier;
  late MockAuthNotifier mockAuthNotifier;

  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test Owner', passwordHash: 'hash', role: 'Owner', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tMember = UserEntity(id: 'u2', email: 'member@test.com', fullName: 'Test Member', passwordHash: 'hash', role: 'Member', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tPendingMember = UserEntity(id: 'u3', email: 'pending@test.com', fullName: 'Test Pending', passwordHash: 'hash', role: 'Member', status: 'Pending', createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUp(() {
    Animate.restartOnHotReload = false;
    mockProjectMembersNotifier = MockProjectMembersNotifier(ProjectMembersState(members: [tUser, tMember, tPendingMember]));
    mockWorkspaceMembersNotifier = MockWorkspaceMembersNotifier(WorkspaceMembersState(members: [tUser, tMember, tPendingMember]));
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        projectMembersProvider('p1').overrideWith((ref) => mockProjectMembersNotifier),
        workspaceMembersProvider('ws1').overrideWith((ref) => mockWorkspaceMembersNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: const MaterialApp(
        home: ProjectMembersScreen(projectId: 'p1', workspaceId: 'ws1'),
      ),
    );
  }

  group('ProjectMembersScreen Widget Tests', () {
    testWidgets('renders members list correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Project Members'), findsOneWidget);
      expect(find.text('Test Owner'), findsOneWidget);
      expect(find.text('Test Member'), findsOneWidget);
      expect(find.text('Test Pending'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget); // Pending status
    });

    testWidgets('shows add member bottom sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      expect(find.text('Add Workspace Member to Project'), findsOneWidget);
    });
  });
}
