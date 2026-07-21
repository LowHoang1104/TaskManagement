import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';
import 'package:task_management/feature/presentation/taskflow/screens/workspace_members_screen.dart';

class _MockAuthService extends Mock implements IAuthService {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initial) : super(_MockAuthService()) {
    state = initial;
  }
}

/// Members notifier stub — holds a fixed member list and records `inviteMember`
/// calls, so the widget tree renders without DI / network.
class FakeWorkspaceMembersNotifier extends StateNotifier<WorkspaceMembersState>
    implements WorkspaceMembersNotifier {
  FakeWorkspaceMembersNotifier(super.initial);

  @override
  final String workspaceId = 'w1';

  bool inviteCalled = false;
  String? lastEmail;
  bool inviteResult = true;

  @override
  Future<void> fetchMembers() async {}

  @override
  Future<bool> inviteMember(String email) async {
    inviteCalled = true;
    lastEmail = email;
    return inviteResult;
  }

  @override
  Future<bool> updateRole(String userId, String newRole) async => true;

  @override
  Future<bool> removeMember(String userId) async => true;
}

void main() {
  final tOwner = UserEntity(
    id: 'u1',
    fullName: 'Alice Owner',
    email: 'alice@test.com',
    passwordHash: '',
    role: 'Owner',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
  final tMember = UserEntity(
    id: 'u2',
    fullName: 'Bob Member',
    email: 'bob@test.com',
    passwordHash: '',
    role: 'Member',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late FakeWorkspaceMembersNotifier fakeMembers;

  /// [currentUser] decides the viewer's role (Owner unlocks the invite card).
  Future<void> pump(WidgetTester tester, UserEntity currentUser) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith((ref) => FakeAuthNotifier(AuthState(user: currentUser))),
          workspaceMembersProvider.overrideWith((ref, arg) => fakeMembers),
        ],
        child: const MaterialApp(
          home: WorkspaceMembersScreen(
            workspaceId: 'w1',
            workspaceName: 'My Workspace',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    fakeMembers = FakeWorkspaceMembersNotifier(
      WorkspaceMembersState(members: [tOwner, tMember]),
    );
  });

  group('WorkspaceMembersScreen Widget Tests', () {
    testWidgets('renders header and member rows', (tester) async {
      await pump(tester, tOwner);

      expect(find.text('Members'), findsWidgets);
      expect(find.text('Alice Owner'), findsOneWidget);
      expect(find.text('Bob Member'), findsOneWidget);
      expect(find.text('My Workspace · 2 people'), findsOneWidget);
    });

    testWidgets('owner sees invite card and delete workspace action',
        (tester) async {
      await pump(tester, tOwner);

      expect(find.text('Invite to workspace'), findsOneWidget);
      expect(find.text('Send invite'), findsOneWidget);
      expect(find.text('Delete workspace'), findsOneWidget);
    });

    testWidgets('non-owner does not see invite card', (tester) async {
      await pump(tester, tMember);

      expect(find.text('Invite to workspace'), findsNothing);
      expect(find.text('Send invite'), findsNothing);
      expect(find.text('Delete workspace'), findsNothing);
    });

    testWidgets('invites member and shows success snackbar', (tester) async {
      fakeMembers.inviteResult = true;
      await pump(tester, tOwner);

      await tester.enterText(find.byType(TextField).first, 'new@test.com');
      await tester.tap(find.text('Send invite'));
      await tester.pump(); // finish the async invite
      await tester.pump(const Duration(milliseconds: 400)); // let SnackBar appear

      expect(fakeMembers.inviteCalled, true);
      expect(fakeMembers.lastEmail, 'new@test.com');
      expect(
        find.text('Invitation sent — waiting for them to accept'),
        findsOneWidget,
      );
    });

    testWidgets('does not invite when email is empty', (tester) async {
      await pump(tester, tOwner);

      await tester.tap(find.text('Send invite'));
      await tester.pump();

      expect(fakeMembers.inviteCalled, false);
    });
  });
}
