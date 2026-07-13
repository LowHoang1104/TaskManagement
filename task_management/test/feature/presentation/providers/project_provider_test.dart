import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_project_service.dart';
import 'package:task_management/feature/domain/entities/project_entity.dart';
import 'package:task_management/feature/presentation/providers/project_provider.dart';

class MockProjectService extends Mock implements IProjectService {}

void main() {
  late ProjectNotifier notifier;
  late MockProjectService mockService;
  const tWorkspaceId = 'w1';

  final tProject = ProjectEntity(
    id: 'p1',
    workspaceId: tWorkspaceId,
    name: 'Test Project',
    description: 'Desc',
    ownerId: 'u1',
    progress: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockService = MockProjectService();
    notifier = ProjectNotifier(mockService);
  });

  group('ProjectNotifier - fetchProjects', () {
    test('should set projects when fetch is successful', () async {
      when(() => mockService.getProjects(tWorkspaceId))
          .thenAnswer((_) async => Right([tProject]));

      await notifier.fetchProjects(tWorkspaceId);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      expect(notifier.state.projects.length, 1);
      expect(notifier.state.projects.first.id, 'p1');
    });

    test('should set error when fetch fails', () async {
      when(() => mockService.getProjects(tWorkspaceId))
          .thenAnswer((_) async => const Left('Fetch Error'));

      await notifier.fetchProjects(tWorkspaceId);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
      expect(notifier.state.projects, isEmpty);
    });
  });

  group('ProjectNotifier - createProject', () {
    final newProject = ProjectEntity(
      id: 'p2',
      workspaceId: tWorkspaceId,
      name: 'New Project',
      description: 'New Desc',
      ownerId: 'u1',
      progress: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should add new project to state on success', () async {
      when(() => mockService.createProject(tWorkspaceId, 'New Project', 'New Desc'))
          .thenAnswer((_) async => Right(newProject));

      await notifier.createProject(tWorkspaceId, 'New Project', 'New Desc');

      expect(notifier.state.projects.length, 1);
      expect(notifier.state.projects.last.id, 'p2');
    });

    test('should set error on create failure', () async {
      when(() => mockService.createProject(tWorkspaceId, 'New Project', 'New Desc'))
          .thenAnswer((_) async => const Left('Create Error'));

      await notifier.createProject(tWorkspaceId, 'New Project', 'New Desc');

      expect(notifier.state.error, 'Create Error');
    });
  });

  group('ProjectNotifier - deleteProject', () {
    test('should remove project from state on success', () async {
      when(() => mockService.deleteProject(tWorkspaceId, 'p1'))
          .thenAnswer((_) async => const Right(true));

      // Setup state first
      when(() => mockService.getProjects(tWorkspaceId))
          .thenAnswer((_) async => Right([tProject]));
      await notifier.fetchProjects(tWorkspaceId);
      
      final result = await notifier.deleteProject(tWorkspaceId, 'p1');

      expect(result, true);
      expect(notifier.state.projects, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('should set error on delete failure', () async {
      when(() => mockService.deleteProject(tWorkspaceId, 'p1'))
          .thenAnswer((_) async => const Left('Delete Error'));
      
      final result = await notifier.deleteProject(tWorkspaceId, 'p1');

      expect(result, false);
      expect(notifier.state.error, 'Delete Error');
      expect(notifier.state.isLoading, false);
    });
  });

  group('ProjectNotifier - leaveProject', () {
    test('should remove project from state on success', () async {
      when(() => mockService.leaveProject('p1'))
          .thenAnswer((_) async => const Right(true));

      // Setup state first
      when(() => mockService.getProjects(tWorkspaceId))
          .thenAnswer((_) async => Right([tProject]));
      await notifier.fetchProjects(tWorkspaceId);
      
      final result = await notifier.leaveProject('p1');

      expect(result, true);
      expect(notifier.state.projects, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('should set error on leave failure', () async {
      when(() => mockService.leaveProject('p1'))
          .thenAnswer((_) async => const Left('Leave Error'));
      
      final result = await notifier.leaveProject('p1');

      expect(result, false);
      expect(notifier.state.error, 'Leave Error');
      expect(notifier.state.isLoading, false);
    });
  });
}
