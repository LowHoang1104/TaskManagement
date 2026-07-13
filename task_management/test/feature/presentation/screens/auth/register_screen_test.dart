import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/screens/auth/register_screen.dart';
import 'package:task_management/app/routes/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../helpers/pump_app.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<bool> register(String fullName, String email, String password) async => true;

  @override
  Future<void> logout() async {}
}

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    Animate.restartOnHotReload = false;
    mockAuthNotifier = MockAuthNotifier(AuthState());
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: MaterialApp(
        home: const RegisterScreen(),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('LoginScreen')),
          AppRoutes.workspaceList: (_) => const Scaffold(body: Text('WorkspaceListScreen')),
        },
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders register screen correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets); // Might be in button and text

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('navigates back to login when Log In is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final loginFinder = find.text('Log In');
      await tester.ensureVisible(loginFinder);
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();

      expect(find.text('LoginScreen'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
