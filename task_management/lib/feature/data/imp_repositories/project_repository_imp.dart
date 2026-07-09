import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/entities.dart';
import '../../domain/i_repositories/i_project_repository.dart';

class ProjectRepositoryImp implements IProjectRepository {
  final Dio _dio;

  ProjectRepositoryImp({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<ProjectEntity>>> getProjects(String workspaceId) async {
    try {
      final response = await _dio.get(ProjectEndpoints.byWorkspace(workspaceId));
      final List<dynamic> data = response.data;
      
      final projects = data.map<ProjectEntity>((json) => ProjectEntity(
        id: json['id'],
        workspaceId: json['workspaceId'] ?? workspaceId,
        name: json['name'],
        description: json['description'],
        ownerId: json['ownerId'] ?? 'unknown',
        progress: json['progress'] ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      )).toList();

      return Right(projects);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to load projects');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ProjectEntity>> createProject(String workspaceId, String name, String description) async {
    try {
      final response = await _dio.post(
        ProjectEndpoints.byWorkspace(workspaceId),
        data: {
          'name': name,
          'description': description,
        },
      );
      final json = response.data;
      final project = ProjectEntity(
        id: json['id'],
        workspaceId: json['workspaceId'] ?? workspaceId,
        name: json['name'],
        description: json['description'],
        ownerId: json['ownerId'] ?? 'unknown',
        progress: json['progress'] ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
      return Right(project);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to create project');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<UserEntity>>> getProjectMembers(String projectId) async {
    try {
      final response = await _dio.get(ProjectEndpoints.members(projectId));
      final List<dynamic> data = response.data;
      
      final members = data.map<UserEntity>((json) => UserEntity(
        id: json['id'],
        email: json['email'],
        fullName: json['fullName'],
        avatarUrl: json['avatarUrl'],
        role: json['role'] ?? 'Member',
        status: json['status'] ?? 'Accepted',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
        passwordHash: '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      )).toList();

      return Right(members);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to load project members');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> inviteProjectMember(String projectId, String email) async {
    try {
      final response = await _dio.post(
        ProjectEndpoints.members(projectId),
        data: {'email': email},
      );
      final json = response.data;
      final member = UserEntity(
        id: json['id'],
        email: json['email'],
        fullName: json['fullName'],
        avatarUrl: json['avatarUrl'],
        role: json['role'] ?? 'Member',
        status: json['status'] ?? 'Pending',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
        passwordHash: '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
      return Right(member);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to invite member');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> updateProjectMemberRole(String projectId, String userId, String newRole) async {
    try {
      final response = await _dio.put(
        '${ProjectEndpoints.members(projectId)}/$userId/role',
        data: {'role': newRole},
      );
      final json = response.data;
      final member = UserEntity(
        id: json['id'],
        email: json['email'],
        fullName: json['fullName'],
        avatarUrl: json['avatarUrl'],
        role: json['role'] ?? newRole,
        status: json['status'] ?? 'Accepted',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? ''),
        passwordHash: '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
      return Right(member);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to update member role');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> acceptProjectInvitation(String projectId) async {
    try {
      await _dio.put('${ProjectEndpoints.members(projectId)}/accept');
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to accept invitation');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> declineProjectInvitation(String projectId) async {
    try {
      await _dio.delete('${ProjectEndpoints.members(projectId)}/decline');
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to decline invitation');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteProject(String workspaceId, String id) async {
    try {
      await _dio.delete(ProjectEndpoints.delete(workspaceId, id));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to delete project');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> leaveProject(String projectId) async {
    try {
      await _dio.delete('${ProjectEndpoints.members(projectId)}/leave');
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to leave project');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
