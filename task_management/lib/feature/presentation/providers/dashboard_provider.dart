import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/i_repositories/i_dashboard_repository.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardEntity>>((ref) {
  return DashboardNotifier(sl<IDashboardRepository>());
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardEntity>> {
  final IDashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    state = const AsyncValue.loading();
    final result = await _repository.getDashboardStats();
    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (dashboard) => state = AsyncValue.data(dashboard),
    );
  }
}
