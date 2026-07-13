import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/feature/application/i_services/i_dashboard_service.dart';
import 'package:task_management/feature/domain/entities/dashboard_entity.dart';
import 'package:task_management/feature/presentation/providers/dashboard_provider.dart';

class MockDashboardService extends Mock implements IDashboardService {}

void main() {
  late DashboardNotifier notifier;
  late MockDashboardService mockService;

  final tDashboard = DashboardEntity(
    totalTasksDone: 1,
    totalTasksOngoing: 2,
    tasksToDo: 3,
    tasksInProgress: 4,
    tasksReview: 5,
  );

  setUp(() {
    mockService = MockDashboardService();
    // Stub the constructor call
    when(() => mockService.getDashboardStats())
        .thenAnswer((_) async => Right(tDashboard));

    notifier = DashboardNotifier(mockService);
  });

  group('DashboardNotifier - fetchDashboardStats', () {
    test('should load dashboard stats successfully', () async {
      await Future.delayed(Duration.zero);

      expect(notifier.state, isA<AsyncData<DashboardEntity>>());
      expect(notifier.state.value?.tasksToDo, 3);
    });

    test('should set error on failure', () async {
      when(() => mockService.getDashboardStats())
          .thenAnswer((_) async => const Left('Fetch Error'));
      
      notifier = DashboardNotifier(mockService);
      await Future.delayed(Duration.zero);

      expect(notifier.state, isA<AsyncError>());
    });
  });
}
