import 'package:dartz/dartz.dart';
import '../../domain/entities/dashboard_entity.dart';

abstract class IDashboardService {
  Future<Either<String, DashboardEntity>> getDashboardStats();
}
