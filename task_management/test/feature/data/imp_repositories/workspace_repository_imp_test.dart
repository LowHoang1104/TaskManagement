import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:task_management/core/constants/api_endpoints.dart';
import 'package:task_management/feature/data/imp_repositories/workspace_repository_imp.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late WorkspaceRepositoryImp repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = WorkspaceRepositoryImp(dio: mockDio);
  });

  group('WorkspaceRepositoryImp - getWorkspaces', () {
    final tWorkspacesJson = [
      {
        'id': '1',
        'name': 'Workspace 1',
        'description': 'Desc 1',
        'logoUrl': null,
        'ownerId': 'owner_1',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
      }
    ];

    test('should return Right(List<WorkspaceEntity>) on success', () async {
      when(() => mockDio.get(WorkspaceEndpoints.base)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.base),
            data: tWorkspacesJson,
            statusCode: 200,
          ));

      final result = await repository.getWorkspaces();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, '1');
          expect(r.first.name, 'Workspace 1');
        },
      );
    });

    test('should return Left with error message on failure', () async {
      when(() => mockDio.get(WorkspaceEndpoints.base)).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.base),
        response: Response(requestOptions: RequestOptions(path: WorkspaceEndpoints.base), data: {'message': 'Server Error'}, statusCode: 500),
      ));

      final result = await repository.getWorkspaces();

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Server Error'),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('WorkspaceRepositoryImp - createWorkspace', () {
    const tName = 'New Workspace';
    const tDescription = 'New Description';
    final tWorkspaceJson = {
      'id': '2',
      'name': tName,
      'description': tDescription,
      'ownerId': 'owner_1',
      'createdAt': '2023-01-01T00:00:00.000Z',
      'updatedAt': '2023-01-01T00:00:00.000Z',
    };

    test('should return Right(WorkspaceEntity) on success', () async {
      when(() => mockDio.post(WorkspaceEndpoints.base, data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.base),
            data: tWorkspaceJson,
            statusCode: 201,
          ));

      final result = await repository.createWorkspace(tName, tDescription);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.id, '2');
          expect(r.name, tName);
        },
      );
    });

    test('should return Left with error message on failure', () async {
      when(() => mockDio.post(WorkspaceEndpoints.base, data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.base),
        response: Response(requestOptions: RequestOptions(path: WorkspaceEndpoints.base), data: {'message': 'Bad Request'}, statusCode: 400),
      ));

      final result = await repository.createWorkspace(tName, tDescription);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, 'Bad Request'),
        (r) => fail('Should not return right'),
      );
    });
  });

  group('WorkspaceRepositoryImp - deleteWorkspace', () {
    const tId = '1';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(WorkspaceEndpoints.delete(tId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.delete(tId)),
            statusCode: 200,
          ));

      final result = await repository.deleteWorkspace(tId);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r, true));
    });

    test('should return Left with error message on failure', () async {
      when(() => mockDio.delete(WorkspaceEndpoints.delete(tId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.delete(tId)),
        response: Response(requestOptions: RequestOptions(path: WorkspaceEndpoints.delete(tId)), data: {'message': 'Not Found'}, statusCode: 404),
      ));

      final result = await repository.deleteWorkspace(tId);

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, 'Not Found'), (r) => fail('Should not return right'));
    });
  });

  group('WorkspaceRepositoryImp - getWorkspaceMembers', () {
    const tWorkspaceId = '1';
    final tMembersJson = [
      {
        'id': 'user_1',
        'fullName': 'User One',
        'email': 'user1@test.com',
        'role': 'admin',
      }
    ];

    test('should return Right(List<UserEntity>) on success', () async {
      when(() => mockDio.get(WorkspaceEndpoints.members(tWorkspaceId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.members(tWorkspaceId)),
            data: tMembersJson,
            statusCode: 200,
          ));

      final result = await repository.getWorkspaceMembers(tWorkspaceId);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, 'user_1');
          expect(r.first.role, 'admin');
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.get(WorkspaceEndpoints.members(tWorkspaceId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.members(tWorkspaceId)),
        message: 'Network Error',
      ));

      final result = await repository.getWorkspaceMembers(tWorkspaceId);

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, 'Network Error'), (r) => fail('Should not return right'));
    });
  });

  group('WorkspaceRepositoryImp - inviteWorkspaceMember', () {
    const tWorkspaceId = '1';
    const tEmail = 'new@test.com';
    final tMemberJson = {
      'id': 'user_2',
      'fullName': 'User Two',
      'email': tEmail,
      'role': 'member',
    };

    test('should return Right(UserEntity) on success', () async {
      when(() => mockDio.post(WorkspaceEndpoints.members(tWorkspaceId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.members(tWorkspaceId)),
            data: tMemberJson,
            statusCode: 200,
          ));

      final result = await repository.inviteWorkspaceMember(tWorkspaceId, tEmail);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) {
          expect(r.id, 'user_2');
          expect(r.email, tEmail);
        },
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.post(WorkspaceEndpoints.members(tWorkspaceId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.members(tWorkspaceId)),
        message: 'Network Error',
      ));

      final result = await repository.inviteWorkspaceMember(tWorkspaceId, tEmail);

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, 'Network Error'), (r) => fail('Should not return right'));
    });
  });

  group('WorkspaceRepositoryImp - updateWorkspaceMemberRole', () {
    const tWorkspaceId = '1';
    const tUserId = 'user_2';
    const tNewRole = 'admin';
    final tMemberJson = {
      'id': tUserId,
      'fullName': 'User Two',
      'email': 'new@test.com',
      'role': tNewRole,
    };

    test('should return Right(UserEntity) on success', () async {
      when(() => mockDio.put(WorkspaceEndpoints.memberRole(tWorkspaceId, tUserId), data: any(named: 'data'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.memberRole(tWorkspaceId, tUserId)),
            data: tMemberJson,
            statusCode: 200,
          ));

      final result = await repository.updateWorkspaceMemberRole(tWorkspaceId, tUserId, tNewRole);

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return left'),
        (r) => expect(r.role, tNewRole),
      );
    });

    test('should return Left on failure', () async {
      when(() => mockDio.put(WorkspaceEndpoints.memberRole(tWorkspaceId, tUserId), data: any(named: 'data'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.memberRole(tWorkspaceId, tUserId)),
        message: 'Network Error',
      ));

      final result = await repository.updateWorkspaceMemberRole(tWorkspaceId, tUserId, tNewRole);

      expect(result.isLeft(), true);
    });
  });

  group('WorkspaceRepositoryImp - removeWorkspaceMember', () {
    const tWorkspaceId = '1';
    const tUserId = 'user_2';

    test('should return Right(true) on success', () async {
      when(() => mockDio.delete(WorkspaceEndpoints.member(tWorkspaceId, tUserId))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: WorkspaceEndpoints.member(tWorkspaceId, tUserId)),
            statusCode: 200,
          ));

      final result = await repository.removeWorkspaceMember(tWorkspaceId, tUserId);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return left'), (r) => expect(r, true));
    });

    test('should return Left on failure', () async {
      when(() => mockDio.delete(WorkspaceEndpoints.member(tWorkspaceId, tUserId))).thenThrow(DioException(
        requestOptions: RequestOptions(path: WorkspaceEndpoints.member(tWorkspaceId, tUserId)),
        message: 'Network Error',
      ));

      final result = await repository.removeWorkspaceMember(tWorkspaceId, tUserId);

      expect(result.isLeft(), true);
    });
  });
}
