import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/user_entity.dart';
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

  @override
  Future<Either<String, List<UserEntity>>> getWorkspaceMembers(String workspaceId) async {
    try {
      final response = await _dio.get(WorkspaceEndpoints.members(workspaceId));
      final List<dynamic> data = response.data;
      final members = data.map((json) => UserEntity(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        passwordHash: '',
        avatarUrl: json['avatarUrl'],
        role: json['role'],
        status: json['status'] ?? 'Accepted',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
      return Right(members);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to load workspace members');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> acceptWorkspaceInvite(String workspaceId) async {
    try {
      await _dio.post(WorkspaceEndpoints.accept(workspaceId));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to accept invite');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> declineWorkspaceInvite(String workspaceId) async {
    try {
      await _dio.post(WorkspaceEndpoints.decline(workspaceId));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to decline invite');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> inviteWorkspaceMember(String workspaceId, String email) async {
    try {
      final response = await _dio.post(
        WorkspaceEndpoints.members(workspaceId),
        data: {'email': email},
      );
      final json = response.data;
      final member = UserEntity(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        passwordHash: '',
        avatarUrl: json['avatarUrl'],
        role: json['role'],
        status: json['status'] ?? 'Accepted',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return Right(member);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to invite member');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> updateWorkspaceMemberRole(String workspaceId, String userId, String newRole) async {
    try {
      final response = await _dio.put(
        WorkspaceEndpoints.memberRole(workspaceId, userId),
        data: {'role': newRole},
      );
      final json = response.data;
      final member = UserEntity(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        passwordHash: '',
        avatarUrl: json['avatarUrl'],
        role: json['role'],
        status: json['status'] ?? 'Accepted',
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return Right(member);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to update member role');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> removeWorkspaceMember(String workspaceId, String userId) async {
    try {
      await _dio.delete(WorkspaceEndpoints.member(workspaceId, userId));
      return const Right(true);
    } on DioException catch (e) {
      return Left(e.response?.data?['message'] ?? e.message ?? 'Failed to remove member');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
