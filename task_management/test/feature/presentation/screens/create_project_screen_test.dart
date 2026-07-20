import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/project_provider.dart';
import 'package:task_management/feature/presentation/taskflow/screens/create_project_screen.dart';

class _MockAuthService extends Mock implements IAuthService {}

/// Auth notifier stub: reuses the real notifier but injects a fixed state so
/// the screen has a signed-in user without touching DI / network.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initial) : super(_MockAuthService()) {
    state = initial;
  }
}

/// Project notifier stub — records `createProject` calls and lets each test
/// decide whether the operation "fails" by seeding an error into the state.
class FakeProjectNotifier extends StateNotifier<ProjectState>
    implements ProjectNotifier {
  FakeProjectNotifier() : super(ProjectState());

  bool createCalled = false;
  String? nextError;

  @override
  Future<void> createProject(
      String workspaceId, String name, String description) async {
    createCalled = true;
    state = state.copyWith(error: nextError);
  }

  @override
  Future<void> fetchProjects(String workspaceId) async {}

  @override
  Future<bool> deleteProject(String workspaceId, String id) async => true;

  @override
  Future<bool> leaveProject(String id) async => true;
}

void main() {
  final tUser = UserEntity(
    id: 'u1',
    fullName: 'Test User',
    email: 'test@test.com',
    passwordHash: '',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late FakeProjectNotifier fakeProject;

  setUp(() {
    fakeProject = FakeProjectNotifier();
  });

  /// Pumps a host screen with a button that pushes [CreateProjectScreen], so
  /// the screen is a real pushed route (its `Navigator.pop` on success works).
  Future<void> pumpAndOpen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith((ref) => FakeAuthNotifier(AuthState(user: tUser))),
          projectNotifierProvider.overrideWith((ref, arg) => fakeProject),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateProjectScreen(
                        workspaceId: 'w1',
                        workspaceName: 'My Workspace',
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('CreateProjectScreen Widget Tests', () {
    testWidgets('renders form fields and create button', (tester) async {
      await pumpAndOpen(tester);

      expect(find.text('New project'), findsOneWidget);
      // TfLabeledField renders its label upper-cased.
      expect(find.text('PROJECT NAME'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Create project'), findsOneWidget);
      expect(find.text('My Workspace'), findsOneWidget);
    });

    testWidgets('shows snackbar and does not create when name is empty',
        (tester) async {
      await pumpAndOpen(tester);

      await tester.tap(find.text('Create project'));
      await tester.pump(); // let the SnackBar appear

      expect(find.text('Please enter a project name'), findsOneWidget);
      expect(fakeProject.createCalled, false);
      // Still on the create screen.
      expect(find.text('New project'), findsOneWidget);
    });

    testWidgets('creates project and pops on success', (tester) async {
      fakeProject.nextError = null; // success
      await pumpAndOpen(tester);

      await tester.enterText(find.byType(TextField).first, 'Website Revamp');
      await tester.tap(find.text('Create project'));
      await tester.pumpAndSettle();

      expect(fakeProject.createCalled, true);
      // Popped back to the host screen.
      expect(find.text('open'), findsOneWidget);
      expect(find.text('New project'), findsNothing);
    });

    testWidgets('shows error snackbar and stays when create fails',
        (tester) async {
      fakeProject.nextError = 'Server error';
      await pumpAndOpen(tester);

      await tester.enterText(find.byType(TextField).first, 'Website Revamp');
      await tester.tap(find.text('Create project'));
      await tester.pump();

      expect(fakeProject.createCalled, true);
      expect(find.text('Server error'), findsOneWidget);
      // Did not pop.
      expect(find.text('New project'), findsOneWidget);
    });
  });
}
