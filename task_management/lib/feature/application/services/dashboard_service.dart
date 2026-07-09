import '../i_services/i_dashboard_service.dart';
import '../../domain/i_repositories/i_dashboard_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardService implements IDashboardService {
  final IDashboardRepository _repository;

  DashboardService(this._repository);

  @override
  Future<Either<String, DashboardEntity>> getDashboardStats() async {
    return await _repository.getDashboardStats();
  }
}
