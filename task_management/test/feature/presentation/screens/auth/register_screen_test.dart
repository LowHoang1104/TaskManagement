import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';
import 'package:task_management/app/routes/app_routes.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/screens/auth/register_screen.dart';
import 'package:task_management/feature/presentation/taskflow/widgets/tf_widgets.dart';
import 'package:task_management/core/di/injection_container.dart' as di;
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';

class MockAuthService extends Mock implements IAuthService {}

class FakeUserEntity extends Fake implements UserEntity {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class RouteFake extends Fake implements Route<dynamic> {}

class MockSignalRService extends Mock implements SignalRService {}

void main() {
  late MockAuthService mockAuthService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUpAll(() {
    registerFallbackValue(RouteFake());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockNavigatorObserver = MockNavigatorObserver();
    // Ensure a mocked SignalRService is registered to avoid GetIt errors
    final mockSignalR = MockSignalRService();
    if (di.sl.isRegistered<SignalRService>()) {
      di.sl.unregister<SignalRService>();
    }
    di.sl.registerSingleton<SignalRService>(mockSignalR);
      when(() => mockSignalR.startConnection()).thenAnswer((_) async {});
      when(() => mockSignalR.stopConnection()).thenAnswer((_) async {});
  });

  Widget createRegisterScreen() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
          AppRoutes.home: (_) => const Scaffold(body: Text('Home Screen')),
        },
        home: const RegisterScreen(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('should display initial form state widgets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterScreen());

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Start organising in under a minute.'), findsOneWidget);
      expect(find.widgetWithText(TfLabeledField, 'FULL NAME'), findsOneWidget);
      expect(find.widgetWithText(TfLabeledField, 'EMAIL'), findsOneWidget);
      expect(find.widgetWithText(TfLabeledField, 'PASSWORD'), findsOneWidget);
      expect(find.widgetWithText(TfPrimaryButton, 'Send OTP'), findsOneWidget);
    });

    testWidgets('should show password strength status dynamically when user enters text', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterScreen());

      // Initial state should have no status label
      expect(find.text('Weak'), findsNothing);

      // Enter short password
      final pwdField = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'PASSWORD'),
        matching: find.byType(TextField),
      );
      await tester.enterText(pwdField, '123');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      // Enter good password length
      await tester.enterText(pwdField, '1234567');
      await tester.pump();
      expect(find.text('Good'), findsOneWidget);

      // Enter strong password length
      await tester.enterText(pwdField, '12345678910');
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('should step forward to OTP screen UI when Send OTP service call returns true', (WidgetTester tester) async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createRegisterScreen());

      final nameField = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'FULL NAME'),
        matching: find.byType(TextField),
      );
      final emailField = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'EMAIL'),
        matching: find.byType(TextField),
      );
      // reuse pwdField declared earlier (if not in scope, recreate)
      final pwdFieldLocal = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'PASSWORD'),
        matching: find.byType(TextField),
      );

      await tester.enterText(nameField, 'John Doe');
      await tester.enterText(emailField, 'john.doe@acme.co');
      await tester.enterText(pwdFieldLocal, 'securepassword');
      
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pump();

      verify(() => mockAuthService.sendOtp('john.doe@acme.co')).called(1);

      // UI should change state to OTP collection view layout
      expect(find.textContaining('Enter the 6-digit code sent to'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
      expect(find.widgetWithText(TfPrimaryButton, 'Verify & Create Account'), findsOneWidget);
    });
    testWidgets('should show error notification banner if OTP verification fails on business logic paths', (WidgetTester tester) async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));
      when(() => mockAuthService.verifyOtpAndRegister(any(), any(), any(), any()))
          .thenAnswer((_) async => const Left('Invalid OTP verification code'));

      await tester.pumpWidget(createRegisterScreen());

      // Move into sub-view state
      final emailField2 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'EMAIL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(emailField2, 'john.doe@acme.co');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pump();

      final otpField2 = find.descendant(
        of: find.byType(Pinput),
        matching: find.byType(EditableText),
      );
      await tester.enterText(otpField2, '000000');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Verify & Create Account'));
      await tester.pump();

      expect(find.text('Invalid OTP verification code'), findsOneWidget);
    });

    testWidgets('should return safely back to initialization parameters screen configuration if Change Email is triggered', (WidgetTester tester) async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createRegisterScreen());

      final emailField3 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'EMAIL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(emailField3, 'test@acme.co');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pump();

      // Tap 'Change email' button element
      await tester.tap(find.text('Change email'));
      await tester.pump();

      // Should render the registration form details once again
      expect(find.widgetWithText(TfPrimaryButton, 'Send OTP'), findsOneWidget);
    });

    testWidgets('should not call sendOtp when email is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterScreen());

      // Leave email empty and tap Send OTP
      final nameField2 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'FULL NAME'),
        matching: find.byType(TextField),
      );
      final pwdField2 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'PASSWORD'),
        matching: find.byType(TextField),
      );
      await tester.enterText(nameField2, 'Jane');
      await tester.enterText(pwdField2, 'pass1234');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pump();

      verifyNever(() => mockAuthService.sendOtp(any()));
    });

    testWidgets('should not call verifyOtpAndRegister when OTP length is not 6', (WidgetTester tester) async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createRegisterScreen());

      // Move to OTP view
      final emailField4 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'EMAIL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(emailField4, 'jane@acme.co');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pump();

      // Enter short OTP and tap verify
      final otpField3 = find.descendant(
        of: find.byType(Pinput),
        matching: find.byType(EditableText),
      );
      await tester.enterText(otpField3, '123');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Verify & Create Account'));
      await tester.pump();

      verifyNever(() => mockAuthService.verifyOtpAndRegister(any(), any(), any(), any()));
    });

    testWidgets('should navigate to login when Sign in is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterScreen());

      final signInTextFinder = find.byWidgetPredicate((w) {
        if (w is Text) {
          if (w.data != null && w.data!.contains('Sign in')) return true;
          if (w.textSpan != null && w.textSpan!.toPlainText().contains('Sign in')) return true;
        }
        return false;
      });
      final signInGesture = find.ancestor(of: signInTextFinder, matching: find.byType(GestureDetector));
      await tester.tap(signInGesture);
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('back arrow should navigate to login when there is nothing to pop', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterScreen());

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('should show resend countdown text after sending OTP', (WidgetTester tester) async {
      when(() => mockAuthService.sendOtp(any())).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createRegisterScreen());

      final emailField5 = find.descendant(
        of: find.widgetWithText(TfLabeledField, 'EMAIL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(emailField5, 'resend@acme.co');
      await tester.tap(find.widgetWithText(TfPrimaryButton, 'Send OTP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resend code in'), findsOneWidget);
    });
  });
}