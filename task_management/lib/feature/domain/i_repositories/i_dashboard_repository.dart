import 'package:dartz/dartz.dart';
import '../entities/dashboard_entity.dart';

abstract class IDashboardRepository {
  Future<Either<String, DashboardEntity>> getDashboardStats();
}
