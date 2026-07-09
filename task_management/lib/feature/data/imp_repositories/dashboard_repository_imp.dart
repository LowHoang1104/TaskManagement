import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/i_repositories/i_dashboard_repository.dart';

class DashboardRepositoryImp implements IDashboardRepository {
  final Dio _dio;

  DashboardRepositoryImp(this._dio);

  @override
  Future<Either<String, DashboardEntity>> getDashboardStats() async {
    try {
      final response = await _dio.get(UserEndpoints.dashboard);
      return Right(DashboardEntity.fromJson(response.data));
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        return Left(e.response?.data['message'] ?? 'Failed to load dashboard data');
      }
      return Left(e.message ?? 'Network error');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
