import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/project_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ProjectRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = ProjectRepositoryImp(dio: mockDio);
  });

  group('ProjectRepositoryImp - getProjects', () {
    const tWorkspaceId = 'w1';
    final tProjectsJson = [
      {
        'id': 'p1',
        'workspaceId': tWorkspaceId,
        'name': 'Project 1',
        'description': 'Desc',
        'ownerId': 'owner_1',
        'progress': 50,
      }
    ];

    test('should return Right(List<ProjectEntity>) on success', () async {
      when(() => mockDio.get(ProjectEndpoints.byWorkspace(tWorkspaceId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.byWorkspace(tWorkspaceId)),
            data: tProjectsJson,
            statusCode: 200,
          ));

      final result = await repository.getProjects(tWorkspaceId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'p1');
          expect(r.first.progress, 50);
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(ProjectEndpoints.byWorkspace(tWorkspaceId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.byWorkspace(tWorkspaceId)),
        message: 'Network Error',
      ));

      final result = await repository.getProjects(tWorkspaceId);

      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - createProject', () {
    const tWorkspaceId = 'w1';
    const tName = 'New Project';
    const tDescription = 'New Description';
    final tProjectJson = {
      'id': 'p2',
      'workspaceId': tWorkspaceId,
      'name': tName,
      'description': tDescription,
      'progress': 0,
    };

    test('should return Right(ProjectEntity) on success', () async {
      when(() => mockDio.post(ProjectEndpoints.byWorkspace(tWorkspaceId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.byWorkspace(tWorkspaceId)),
            data: tProjectJson,
            statusCode: 201,
          ));

      final result = await repository.createProject(tWorkspaceId, tName, tDescription);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.name, tName));
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(ProjectEndpoints.byWorkspace(tWorkspaceId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.byWorkspace(tWorkspaceId)),
        message: 'Network Error',
      ));

      final result = await repository.createProject(tWorkspaceId, tName, tDescription);

      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - deleteProject', () {
    const tWorkspaceId = 'w1';
    const tId = 'p1';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(ProjectEndpoints.delete(tWorkspaceId, tId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.delete(tWorkspaceId, tId)),
            statusCode: 200,
          ));

      final result = await repository.deleteProject(tWorkspaceId, tId);

      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(ProjectEndpoints.delete(tWorkspaceId, tId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.delete(tWorkspaceId, tId)),
        message: 'Error',
      ));

      final result = await repository.deleteProject(tWorkspaceId, tId);

      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - getProjectMembers', () {
    const tProjectId = 'p1';
    final tMembersJson = [
      {'id': 'u1', 'email': 'test@test.com', 'fullName': 'User 1', 'role': 'Admin'},
    ];

    test('should return Right(List<UserEntity>) on success', () async {
      when(() => mockDio.get(ProjectEndpoints.members(tProjectId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
            data: tMembersJson,
            statusCode: 200,
          ));

      final result = await repository.getProjectMembers(tProjectId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'u1');
          expect(r.first.role, 'Admin');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(ProjectEndpoints.members(tProjectId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
        message: 'Error',
      ));

      final result = await repository.getProjectMembers(tProjectId);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - inviteProjectMember', () {
    const tProjectId = 'p1';
    const tEmail = 'new@test.com';
    final tMemberJson = {'id': 'u2', 'email': tEmail, 'fullName': 'User 2', 'status': 'Pending'};

    test('should return Right(UserEntity) on success', () async {
      when(() => mockDio.post(ProjectEndpoints.members(tProjectId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
            data: tMemberJson,
            statusCode: 200,
          ));

      final result = await repository.inviteProjectMember(tProjectId, tEmail);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.email, tEmail));
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(ProjectEndpoints.members(tProjectId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
        message: 'Error',
      ));

      final result = await repository.inviteProjectMember(tProjectId, tEmail);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - updateProjectMemberRole', () {
    const tProjectId = 'p1';
    const tUserId = 'u1';
    const tNewRole = 'Admin';
    final tPath = '${ProjectEndpoints.members(tProjectId)}/$tUserId/role';
    final tMemberJson = {'id': tUserId, 'email': 'test@test.com', 'fullName': 'User 1', 'role': tNewRole};

    test('should return Right(UserEntity) on success', () async {
      when(() => mockDio.put(tPath, data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: tPath),
            data: tMemberJson,
            statusCode: 200,
          ));

      final result = await repository.updateProjectMemberRole(tProjectId, tUserId, tNewRole);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r.role, tNewRole));
    });

    test('should return Left on failure', () async {
      when(() => mockDio.put(tPath, data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: tPath),
        message: 'Error',
      ));

      final result = await repository.updateProjectMemberRole(tProjectId, tUserId, tNewRole);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - acceptProjectInvitation', () {
    const tProjectId = 'p1';
    final tPath = '${ProjectEndpoints.members(tProjectId)}/accept';

    test('should return Right(true) on success', () async {
      when(() => mockDio.put(tPath)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: tPath),
            statusCode: 200,
          ));

      final result = await repository.acceptProjectInvitation(tProjectId);
      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.put(tPath)).thenThrow(DioException(
        requestOptions: RequestOptions(path: tPath),
        message: 'Error',
      ));

      final result = await repository.acceptProjectInvitation(tProjectId);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - declineProjectInvitation', () {
    const tProjectId = 'p1';
    final tPath = '${ProjectEndpoints.members(tProjectId)}/decline';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(tPath)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: tPath),
            statusCode: 200,
          ));

      final result = await repository.declineProjectInvitation(tProjectId);
      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(tPath)).thenThrow(DioException(
        requestOptions: RequestOptions(path: tPath),
        message: 'Error',
      ));

      final result = await repository.declineProjectInvitation(tProjectId);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - leaveProject', () {
    const tProjectId = 'p1';
    final tPath = '${ProjectEndpoints.byId(tProjectId)}/members/leave';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(tPath)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: tPath),
            statusCode: 200,
          ));

      final result = await repository.leaveProject(tProjectId);
      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(tPath)).thenThrow(DioException(
        requestOptions: RequestOptions(path: tPath),
        message: 'Error',
      ));

      final result = await repository.leaveProject(tProjectId);
      expect(result.isLeft(), true);
    });
  });

  group('ProjectRepositoryImp - removeProjectMember', () {
    const tProjectId = 'p1';
    const tUserId = 'u1';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(ProjectEndpoints.member(tProjectId, tUserId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.member(tProjectId, tUserId)),
            statusCode: 200,
          ));

      final result = await repository.removeProjectMember(tProjectId, tUserId);
      expect(result.isRight(), true);
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(ProjectEndpoints.member(tProjectId, tUserId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.member(tProjectId, tUserId)),
        message: 'Error',
      ));

      final result = await repository.removeProjectMember(tProjectId, tUserId);
      expect(result.isLeft(), true);
    });
  });
}
