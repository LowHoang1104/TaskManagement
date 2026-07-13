import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/core/di/injection_container.dart';
import 'package:task_management/feature/application/i_services/i_workspace_service.dart';
import 'package:task_management/feature/domain/entities/user_entity.dart';
import 'package:task_management/feature/presentation/providers/workspace_members_provider.dart';

class MockWorkspaceService extends Mock implements IWorkspaceService {}

void main() {
  late WorkspaceMembersNotifier notifier;
  late MockWorkspaceService mockService;
  const tWorkspaceId = 'w1';

  final tUser = UserEntity(
    id: 'u1',
    fullName: 'Test User',
    email: 'test@test.com',
    passwordHash: '',
    role: 'Member',
    avatarUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    mockService = MockWorkspaceService();
    sl.registerLazySingleton<IWorkspaceService>(() => mockService);
  });

  setUp(() {
    // Stub fetchMembers because it's called in constructor
    when(() => mockService.getWorkspaceMembers(tWorkspaceId))
        .thenAnswer((_) async => Right([tUser]));

    notifier = WorkspaceMembersNotifier(tWorkspaceId);
  });

  tearDownAll(() {
    sl.reset();
  });

  group('WorkspaceMembersNotifier - fetchMembers', () {
    test('should set members when fetch is successful', () async {
      await Future.delayed(Duration.zero); // wait for constructor fetch

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      expect(notifier.state.members.length, 1);
      expect(notifier.state.members.first.id, 'u1');
    });

    test('should set error when fetch fails', () async {
      when(() => mockService.getWorkspaceMembers(tWorkspaceId))
          .thenAnswer((_) async => const Left('Fetch Error'));
      notifier = WorkspaceMembersNotifier(tWorkspaceId);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
      expect(notifier.state.members, isEmpty);
    });
  });

  group('WorkspaceMembersNotifier - inviteMember', () {
    final newUser = UserEntity(
      id: 'u2',
      fullName: 'New User',
      email: 'new@test.com',
      passwordHash: '',
      role: 'Member',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should add new member to state on success', () async {
      when(() => mockService.inviteWorkspaceMember(tWorkspaceId, 'new@test.com'))
          .thenAnswer((_) async => Right(newUser));

      await Future.delayed(Duration.zero);
      final result = await notifier.inviteMember('new@test.com');

      expect(result, true);
      expect(notifier.state.members.length, 2);
      expect(notifier.state.members.last.id, 'u2');
    });

    test('should set error on invite failure', () async {
      when(() => mockService.inviteWorkspaceMember(tWorkspaceId, 'new@test.com'))
          .thenAnswer((_) async => const Left('Invite Error'));

      await Future.delayed(Duration.zero);
      final result = await notifier.inviteMember('new@test.com');

      expect(result, false);
      expect(notifier.state.error, 'Invite Error');
    });
  });

  group('WorkspaceMembersNotifier - updateRole', () {
    final updatedUser = UserEntity(
      id: 'u1',
      fullName: 'Test User',
      email: 'test@test.com',
      passwordHash: '',
      role: 'Admin',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should update member role in state on success', () async {
      when(() => mockService.updateWorkspaceMemberRole(tWorkspaceId, 'u1', 'Admin'))
          .thenAnswer((_) async => Right(updatedUser));

      await Future.delayed(Duration.zero);
      final result = await notifier.updateRole('u1', 'Admin');

      expect(result, true);
      expect(notifier.state.members.first.role, 'Admin');
    });

    test('should set error on update failure', () async {
      when(() => mockService.updateWorkspaceMemberRole(tWorkspaceId, 'u1', 'Admin'))
          .thenAnswer((_) async => const Left('Update Error'));

      await Future.delayed(Duration.zero);
      final result = await notifier.updateRole('u1', 'Admin');

      expect(result, false);
      expect(notifier.state.error, 'Update Error');
    });
  });

  group('WorkspaceMembersNotifier - removeMember', () {
    test('should remove member from state on success', () async {
      when(() => mockService.removeWorkspaceMember(tWorkspaceId, 'u1'))
          .thenAnswer((_) async => const Right(true));

      await Future.delayed(Duration.zero);
      final result = await notifier.removeMember('u1');

      expect(result, true);
      expect(notifier.state.members, isEmpty);
    });

    test('should set error on remove failure', () async {
      when(() => mockService.removeWorkspaceMember(tWorkspaceId, 'u1'))
          .thenAnswer((_) async => const Left('Remove Error'));

      await Future.delayed(Duration.zero);
      final result = await notifier.removeMember('u1');

      expect(result, false);
      expect(notifier.state.error, 'Remove Error');
    });
  });
}
