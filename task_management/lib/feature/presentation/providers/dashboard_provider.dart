import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../application/i_services/i_dashboard_service.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardEntity>>((ref) {
  return DashboardNotifier(sl<IDashboardService>());
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardEntity>> {
  final IDashboardService _service;

  DashboardNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    state = const AsyncValue.loading();
    final result = await _service.getDashboardStats();
    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (dashboard) => state = AsyncValue.data(dashboard),
    );
  }
}
