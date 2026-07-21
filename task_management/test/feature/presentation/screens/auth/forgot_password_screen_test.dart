import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/screens/auth/forgot_password_screen.dart';

class _MockAuthService extends Mock implements IAuthService {}

class MockAuthNotifier extends AuthNotifier with Mock {
  MockAuthNotifier(AuthState initialState) : super(_MockAuthService()) {
    state = initialState;
  }

  // Override the specific method used by the UI
  @override
  Future<bool> forgotPassword(String email) async => true;
}

class TestWidgetWrapper extends StatelessWidget {
  final Widget child;
  const TestWidgetWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
    );
  }
}

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier(AuthState());
  });

  Widget createForgotPasswordScreen() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: const TestWidgetWrapper(
        child: ForgotPasswordScreen(),
      ),
    );
  }

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('should render initial UI components accurately', (WidgetTester tester) async {
      await tester.pumpWidget(createForgotPasswordScreen());

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Enter your email to receive a password reset code.'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Send Reset Code'), findsOneWidget);
    });

    testWidgets('should display validation error message when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createForgotPasswordScreen());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should display validation error message when email is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(createForgotPasswordScreen());

      await tester.enterText(find.byType(TextFormField), 'invalidemail.com');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show loading layout when provider status is authenticating', (WidgetTester tester) async {
      // Adjust the state structure here to match your actual AuthState class implementation
      mockAuthNotifier.state = mockAuthNotifier.state.copyWith(isLoading: true);

      await tester.pumpWidget(createForgotPasswordScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Send Reset Code'), findsNothing);
    }); 
  });
}