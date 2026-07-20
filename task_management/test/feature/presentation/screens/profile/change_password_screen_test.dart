import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/profile/change_password_screen.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  
  bool shouldSucceed = true;

  @override
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 10)); // simulate network
    if (shouldSucceed) {
      state = AuthState(isLoading: false, user: state.user);
      return true;
    } else {
      state = AuthState(isLoading: false, error: 'Wrong password', user: state.user);
      return false;
    }
  }

  // Not used in this test but required to fulfill interface
  @override Future<bool> login(String e, String p) async => true;
  @override Future<bool> uploadAvatar({required String fileName, required List<int> fileBytes}) async => true;
  @override Future<bool> register(String n, String e, String p) async => true;
  @override Future<void> logout() async {}
}

void main() {
  final tUser = UserEntity(
    id: '1', fullName: 'Test', email: 'test@test.com', 
    passwordHash: '', createdAt: DateTime.now(), updatedAt: DateTime.now()
  );

  Widget createWidgetUnderTest(MockAuthNotifier mockNotifier) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockNotifier),
      ],
      child: const MaterialApp(
        home: ChangePasswordScreen(),
      ),
    );
  }

  group('ChangePasswordScreen Widget Tests', () {
    testWidgets('renders all fields and button', (tester) async {
      final mockNotifier = MockAuthNotifier(AuthState(user: tUser));
      await tester.pumpWidget(createWidgetUnderTest(mockNotifier));

      expect(find.text('Change Password'), findsWidgets);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      final mockNotifier = MockAuthNotifier(AuthState(user: tUser));
      await tester.pumpWidget(createWidgetUnderTest(mockNotifier));

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter current password'), findsOneWidget);
      expect(find.text('Please enter new password'), findsOneWidget);
      expect(find.text('Please confirm new password'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match', (tester) async {
      final mockNotifier = MockAuthNotifier(AuthState(user: tUser));
      await tester.pumpWidget(createWidgetUnderTest(mockNotifier));

      await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), 'oldPass');
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newPass123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newPass456');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows success snackbar and pops on successful change', (tester) async {
      final mockNotifier = MockAuthNotifier(AuthState(user: tUser));
      await tester.pumpWidget(createWidgetUnderTest(mockNotifier));

      await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), 'oldPass');
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newPass123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newPass123');

      await tester.tap(find.text('Save Changes'));
      await tester.pump(); // Start loading
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20)); // Finish network
      await tester.pump(); // Trigger setState

      expect(find.text('Password changed successfully!'), findsOneWidget);
      // Wait for route pop and snackbar to disappear
      await tester.pumpAndSettle();
    });

    testWidgets('shows error snackbar on failure', (tester) async {
      final mockNotifier = MockAuthNotifier(AuthState(user: tUser))..shouldSucceed = false;
      await tester.pumpWidget(createWidgetUnderTest(mockNotifier));

      await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), 'wrongPass');
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newPass123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newPass123');

      await tester.tap(find.text('Save Changes'));
      await tester.pump(); // start loading
      await tester.pump(const Duration(milliseconds: 20)); // finish network
      await tester.pump(); // build snackbar

      expect(find.text('Wrong password'), findsOneWidget);
    });
  });
}
