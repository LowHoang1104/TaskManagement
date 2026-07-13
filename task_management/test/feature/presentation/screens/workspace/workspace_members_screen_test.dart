import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/workspace/workspace_members_screen.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  @override
  Future<bool> register(String name, String email, String password) async => true;
  @override
  Future<void> logout() async {}
  @override
  Future<void> checkAuthStatus() async {}
  @override
  Future<bool> changePassword(String c, String n) async => true;
}

void main() {
  late MockWorkspaceMembersNotifier mockWorkspaceMembersNotifier;
  late MockAuthNotifier mockAuthNotifier;

  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test Owner', passwordHash: 'hash', role: 'Owner', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tMember = UserEntity(id: 'u2', email: 'member@test.com', fullName: 'Test Member', passwordHash: 'hash', role: 'Member', createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUp(() {
    Animate.restartOnHotReload = false;
    mockWorkspaceMembersNotifier = MockWorkspaceMembersNotifier(WorkspaceMembersState(members: [tUser, tMember]));
    mockAuthNotifier = MockAuthNotifier(AuthState(user: tUser));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        workspaceMembersProvider('ws1').overrideWith((ref) => mockWorkspaceMembersNotifier),
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: const MaterialApp(
        home: WorkspaceMembersScreen(workspaceId: 'ws1'),
      ),
    );
  }

  group('WorkspaceMembersScreen Widget Tests', () {
    testWidgets('renders members list correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Workspace Members'), findsOneWidget);
      expect(find.text('Test Owner'), findsOneWidget);
      expect(find.text('Test Member'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
    });

    testWidgets('shows invite dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();

      expect(find.text('Invite Workspace Member'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'new@test.com');
      await tester.tap(find.text('Invite').last);
      await tester.pumpAndSettle();
    });

    testWidgets('shows options menu for member', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the more options on the member (the second item)
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Make Admin'), findsOneWidget);
      expect(find.text('Remove from Workspace'), findsOneWidget);
    });
  });
}
