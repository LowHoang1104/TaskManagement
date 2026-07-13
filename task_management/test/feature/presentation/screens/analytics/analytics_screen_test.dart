import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/presentation/screens/analytics/analytics_screen.dart';
import 'package:task_management/feature/presentation/providers/dashboard_provider.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

class MockDashboardNotifier extends StateNotifier<AsyncValue<DashboardEntity>> implements DashboardNotifier {
  MockDashboardNotifier(super.state);
  @override
  Future<void> fetchDashboardStats() async {}
}

void main() {
  late MockDashboardNotifier mockDashboardNotifier;
  final tStats = DashboardEntity(
    tasksToDo: 5,
    tasksInProgress: 3,
    tasksReview: 2,
    totalTasksDone: 10,
    totalTasksOngoing: 10,
  );

  setUp(() {
    Animate.restartOnHotReload = false;
    mockDashboardNotifier = MockDashboardNotifier(AsyncValue.data(tStats));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        dashboardProvider.overrideWith((ref) => mockDashboardNotifier),
      ],
      child: const MaterialApp(
        home: AnalyticsScreen(),
      ),
    );
  }

  group('AnalyticsScreen Widget Tests', () {
    testWidgets('renders analytics screen with correct data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Analytics Overview'), findsOneWidget);
      expect(find.text('Total Tasks'), findsOneWidget);
      expect(find.text('20'), findsOneWidget); // 5+3+2+10
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      expect(find.text('Task Status Distribution'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
    });
  });
}
