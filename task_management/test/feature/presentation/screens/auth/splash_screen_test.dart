import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/feature/presentation/screens/auth/splash_screen.dart';
import 'package:task_management/app/routes/app_routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.login) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Login Screen')));
        }
        return null;
      },
      home: const SplashScreen(),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('renders logo and text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('TaskFlow'), findsOneWidget);
      expect(find.text('Manage your work easily.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('navigates to login after delay', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Advance time by 3 seconds
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
