import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/app/routes/app_routes.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/screens/auth/forgot_password_screen.dart';
import 'package:task_management/feature/presentation/screens/auth/login_screen.dart';
import 'package:task_management/feature/presentation/taskflow/widgets/tf_widgets.dart';

class MockAuthService extends Mock implements IAuthService {}

class FakeUserEntity extends Fake implements UserEntity {}

class MockAuthNotifier extends AuthNotifier with Mock {
  MockAuthNotifier(super.service);
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class RouteFake extends Fake implements Route<dynamic> {}

void main() {
  late MockAuthService mockAuthService;
  late MockAuthNotifier mockAuthNotifier;
  late MockNavigatorObserver mockNavigatorObserver;

  setUpAll(() {
    registerFallbackValue(RouteFake());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockAuthNotifier = MockAuthNotifier(mockAuthService);
    mockNavigatorObserver = MockNavigatorObserver();
  });

  Widget createLoginScreen() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('Home Screen')),
          AppRoutes.register: (_) => const Scaffold(body: Text('Register Screen')),
        },
        home: const LoginScreen(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should display initial state and email default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to keep your work flowing.'), findsOneWidget);
      expect(find.text('an.nguyen@acme.co'), findsOneWidget); 
      expect(find.widgetWithText(TfPrimaryButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('should show snackbar message when auth state updates with an error string', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      mockAuthNotifier.state = mockAuthNotifier.state.copyWith(error: 'Invalid credentials');
      await tester.pump(); 

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should navigate to ForgotPasswordScreen cleanly when trigger text is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('should switch contextual orientation cleanly to registration screens when custom tab elements are active', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}