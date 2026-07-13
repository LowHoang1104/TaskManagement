import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/screens/auth/login_screen.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import '../../../../helpers/pump_app.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_management/app/routes/app_routes.dart';

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

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier(AuthState());
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: MaterialApp(
        home: const LoginScreen(),
        routes: {
          AppRoutes.register: (_) => const Scaffold(body: Text('RegisterScreen')),
          AppRoutes.workspaceList: (_) => const Scaffold(body: Text('WorkspaceListScreen')),
        },
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    setUp(() {
      Animate.restartOnHotReload = false; // Disable animations to avoid timer issues in some cases
    });

    testWidgets('renders login screen correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('TaskFlow'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      mockAuthNotifier = MockAuthNotifier(AuthState(isLoading: true));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Log In'), findsNothing);

      // Pump a dummy widget to clear timers from flutter_animate and CircularProgressIndicator
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('toggles password visibility when eye icon is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).last;
      
      var textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, true);

      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      await tester.ensureVisible(visibilityIcon);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.byType(TextField).last);
      expect(textField.obscureText, false);
    });

    testWidgets('displays error snackbar when error state changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      mockAuthNotifier.state = AuthState(error: 'Invalid credentials');
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
    
    testWidgets('navigates to register screen when Sign Up is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final signUpFinder = find.text('Sign Up');
      await tester.ensureVisible(signUpFinder);
      await tester.pumpAndSettle();
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.text('RegisterScreen'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('navigates to workspace list when login is successful', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final tUser = UserEntity(id: '1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', createdAt: DateTime.now(), updatedAt: DateTime.now());
      mockAuthNotifier.state = AuthState(user: tUser);
      await tester.pumpAndSettle();

      expect(find.text('WorkspaceListScreen'), findsOneWidget);
    });
  });
}
