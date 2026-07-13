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

  // Adding a few membership tests as examples (same pattern applies to others)
  group('ProjectRepositoryImp - Membership functions', () {
    const tProjectId = 'p1';

    test('getProjectMembers should return Right on success', () async {
      when(() => mockDio.get(ProjectEndpoints.members(tProjectId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
            data: [{'id': 'u1', 'email': 'test@test.com', 'fullName': 'User 1'}],
            statusCode: 200,
          ));

      final result = await repository.getProjectMembers(tProjectId);
      expect(result.isRight(), true);
    });

    test('inviteProjectMember should return Right on success', () async {
      when(() => mockDio.post(ProjectEndpoints.members(tProjectId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ProjectEndpoints.members(tProjectId)),
            data: {'id': 'u2', 'email': 'new@test.com', 'fullName': 'User 2'},
            statusCode: 200,
          ));

      final result = await repository.inviteProjectMember(tProjectId, 'new@test.com');
      expect(result.isRight(), true);
    });

    test('acceptProjectInvitation should return Right on success', () async {
      when(() => mockDio.put('${ProjectEndpoints.members(tProjectId)}/accept')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '${ProjectEndpoints.members(tProjectId)}/accept'),
            statusCode: 200,
          ));

      final result = await repository.acceptProjectInvitation(tProjectId);
      expect(result.isRight(), true);
    });

    test('removeProjectMember should return Left on failure', () async {
      const tUserId = 'u1';
      when(() => mockDio.delete(ProjectEndpoints.member(tProjectId, tUserId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: ProjectEndpoints.member(tProjectId, tUserId)),
        message: 'Error',
      ));

      final result = await repository.removeProjectMember(tProjectId, tUserId);
      expect(result.isLeft(), true);
    });
  });
}
