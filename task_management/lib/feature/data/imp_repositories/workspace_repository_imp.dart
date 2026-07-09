import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/i_repositories/i_workspace_repository.dart';

class WorkspaceRepositoryImp implements IWorkspaceRepository {
  final Dio _dio;

  WorkspaceRepositoryImp({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<WorkspaceEntity>>> getWorkspaces() async {
    try {
      final response = await _dio.get(WorkspaceEndpoints.base);
      
      final List<dynamic> data = response.data;
      final workspaces = data.map((json) => WorkspaceEntity(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        logoUrl: json['logoUrl'],
        ownerId: json['ownerId'] ?? 'unknown',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      )).toList();

      return Right(workspaces);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to load workspaces');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, WorkspaceEntity>> createWorkspace(String name, String? description) async {
    try {
      final response = await _dio.post(
        WorkspaceEndpoints.base,
        data: {
          'name': name,
          'description': description,
        },
      );

      final json = response.data;
      final workspace = WorkspaceEntity(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        logoUrl: json['logoUrl'],
        ownerId: json['ownerId'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

      return Right(workspace);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to create workspace');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteWorkspace(String id) async {
    try {
      await _dio.delete(WorkspaceEndpoints.delete(id));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to delete workspace');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
