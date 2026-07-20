import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/application/i_services/i_dashboard_service.dart';
import 'package:task_management/feature/presentation/screens/profile/profile_screen.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/dashboard_provider.dart';
import 'package:task_management/feature/presentation/providers/theme_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:task_management/app/routes/app_routes.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  Future<bool> login(String email, String password) async => true;
  @override
  Future<bool> register(String name, String email, String password) async => true;
  @override
  Future<void> logout() async {}
  Future<void> checkAuthStatus() async {}
  @override
  Future<bool> changePassword(String currentPassword, String newPassword) async => true;
  @override
  Future<bool> uploadAvatar({required String fileName, required List<int> fileBytes}) async => true;
}

class MockDashboardService implements IDashboardService {
  @override
  Future<Either<String, DashboardEntity>> getDashboardStats() async {
    return Right(DashboardEntity(
      tasksToDo: 0,
      tasksInProgress: 0,
      tasksReview: 0,
      totalTasksDone: 0,
      tasksDoneThisWeek: 0,
      totalTasksOngoing: 0,
    ));
  }
}

class MockDashboardNotifier extends DashboardNotifier {
  MockDashboardNotifier(AsyncValue<DashboardEntity> state) : super(MockDashboardService()) {
    this.state = state;
  }

  @override
  Future<void> fetchDashboardStats() async {}
}

class MockThemeNotifier extends StateNotifier<ThemeMode> implements ThemeModeNotifier {
  MockThemeNotifier(super.state);
  @override
  Future<void> toggleTheme() async {}
  @override
  Future<void> setTheme(ThemeMode mode) async {}
}

void main() {
  final tUser = UserEntity(id: 'u1', email: 'test@test.com', fullName: 'Test User', passwordHash: 'hash', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tStats = DashboardEntity(tasksToDo: 0, tasksInProgress: 0, tasksReview: 0, totalTasksDone: 15, tasksDoneThisWeek: 3, totalTasksOngoing: 5);

  setUp(() {
    Animate.restartOnHotReload = false;
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => MockAuthNotifier(AuthState(user: tUser))),
        dashboardProvider.overrideWith((ref) => MockDashboardNotifier(AsyncValue.data(tStats))),
        themeProvider.overrideWith((ref) => MockThemeNotifier(ThemeMode.light)),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.login) {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Login Screen')));
          }
          if (settings.name == AppRoutes.changePassword) {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Change Password Screen')));
          }
          return null;
        },
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders profile screen and data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@test.com'), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // Initial avatar
      expect(find.text('Tasks Done'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('toggles dark mode switch', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(switchFinder, findsOneWidget);
      
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('handles logout', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final logoutFinder = find.text('Logout');
      await tester.ensureVisible(logoutFinder);
      await tester.pumpAndSettle();

      await tester.tap(logoutFinder);
      await tester.pumpAndSettle();
      
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('navigates to change password screen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final changePwdFinder = find.text('Change Password');
      await tester.ensureVisible(changePwdFinder);
      await tester.pumpAndSettle();

      await tester.tap(changePwdFinder);
      await tester.pumpAndSettle();
      
      expect(find.text('Change Password Screen'), findsOneWidget);
    });
  });
}
