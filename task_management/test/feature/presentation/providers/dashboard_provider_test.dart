import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_dashboard_service.dart';
import 'package:task_management/feature/domain/entities/dashboard_entity.dart';
import 'package:task_management/feature/presentation/providers/dashboard_provider.dart';


// Create a mock class for the service
class MockDashboardService extends Mock implements IDashboardService {}

void main() {
  late MockDashboardService mockDashboardService;
  late DashboardEntity tDashboardEntity;

  setUp(() {
    mockDashboardService = MockDashboardService();
    
    // Initialize dummy data using your DashboardEntity structure
    tDashboardEntity = DashboardEntity(
      totalTasksDone: 10,
      tasksDoneThisWeek: 3,
      totalTasksOngoing: 5,
      tasksToDo: 2,
      tasksInProgress: 2,
      tasksReview: 1,
    );
  });

  ProviderContainer makeProviderContainer(IDashboardService service) {
    final container = ProviderContainer(
      overrides: [
        dashboardProvider.overrideWith((ref) => DashboardNotifier(service)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('DashboardNotifier Tests', () {
    test('initial state is AsyncLoading and triggers fetchDashboardStats on creation', () async {
      // Arrange
      when(() => mockDashboardService.getDashboardStats())
          .thenAnswer((_) async => Right(tDashboardEntity));

      // Act
      final container = makeProviderContainer(mockDashboardService);
      
      // Assert: Verify that the synchronous initial state is Loading
      expect(container.read(dashboardProvider), const AsyncValue<DashboardEntity>.loading());
      
      // Wait for the automatic initialization call inside the constructor to finish
      await container.read(dashboardProvider.notifier).fetchDashboardStats();
    });

    test('should emit AsyncData with correct values when fetchDashboardStats is successful', () async {
      // Arrange
      when(() => mockDashboardService.getDashboardStats())
          .thenAnswer((_) async => Right(tDashboardEntity));

      // Act
      final container = makeProviderContainer(mockDashboardService);
      
      // Wait for the service call to complete
      await container.read(dashboardProvider.notifier).fetchDashboardStats();

      // Assert
      final state = container.read(dashboardProvider);
      
      expect(state.hasValue, true);
      final data = state.value!;
      expect(data.totalTasksDone, 10);
      expect(data.tasksDoneThisWeek, 3);
      expect(data.totalTasksOngoing, 5);
      expect(data.tasksToDo, 2);
      expect(data.tasksInProgress, 2);
      expect(data.tasksReview, 1);
    });
  });

}