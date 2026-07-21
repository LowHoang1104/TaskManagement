import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_workspace_service.dart';
import 'package:task_management/feature/domain/entities/workspace_entity.dart';
import 'package:task_management/feature/presentation/providers/workspace_provider.dart';
import 'package:task_management/feature/data/datasources/remote/signalr_service.dart';
import 'package:task_management/core/di/injection_container.dart' as di;

class MockWorkspaceService extends Mock implements IWorkspaceService {}

class MockSignalRService extends Mock implements SignalRService {}

void main() {
  late WorkspaceNotifier notifier;
  late MockWorkspaceService mockService;

  final tWorkspace = WorkspaceEntity(
    id: 'w1',
    name: 'Test Workspace',
    description: 'Desc',
    logoUrl: null,
    ownerId: 'u1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    // WorkspaceNotifier's constructor reads SignalRService from GetIt, so a
    // mock must be registered before it is built.
    final mockSignalR = MockSignalRService();
    when(() => mockSignalR.workspaceRefreshStream)
        .thenAnswer((_) => const Stream<String>.empty());
    if (di.sl.isRegistered<SignalRService>()) {
      di.sl.unregister<SignalRService>();
    }
    di.sl.registerSingleton<SignalRService>(mockSignalR);

    mockService = MockWorkspaceService();
    // Stub fetchWorkspaces because it's called in constructor
    when(() => mockService.getWorkspaces()).thenAnswer((_) async => Right([tWorkspace]));

    notifier = WorkspaceNotifier(mockService);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  group('WorkspaceNotifier - fetchWorkspaces', () {
    test('should set workspaces when fetch is successful', () async {
      // The constructor calls fetchWorkspaces, wait for it to complete
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, null);
      expect(notifier.state.workspaces.length, 1);
      expect(notifier.state.workspaces.first.id, 'w1');
    });

    test('should set error when fetch fails', () async {
      // Re-initialize for error case
      when(() => mockService.getWorkspaces()).thenAnswer((_) async => const Left('Fetch Error'));
      notifier = WorkspaceNotifier(mockService);

      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
      expect(notifier.state.workspaces, isEmpty);
    });
  });

  group('WorkspaceNotifier - createWorkspace', () {
    final newWorkspace = WorkspaceEntity(
      id: 'w2',
      name: 'New Workspace',
      description: 'New Desc',
      logoUrl: null,
      ownerId: 'u1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should add new workspace to state on success', () async {
      when(() => mockService.createWorkspace('New Workspace', 'New Desc'))
          .thenAnswer((_) async => Right(newWorkspace));

      await Future.delayed(Duration.zero); // Wait for constructor fetch
      await notifier.createWorkspace('New Workspace', 'New Desc');

      expect(notifier.state.workspaces.length, 2);
      expect(notifier.state.workspaces.last.id, 'w2');
    });

    test('should set error on create failure', () async {
      when(() => mockService.createWorkspace('New Workspace', 'New Desc'))
          .thenAnswer((_) async => const Left('Create Error'));

      await Future.delayed(Duration.zero); // Wait for constructor fetch
      await notifier.createWorkspace('New Workspace', 'New Desc');

      expect(notifier.state.error, 'Create Error');
    });
  });

  group('WorkspaceNotifier - deleteWorkspace', () {
    test('should remove workspace from state on success', () async {
      when(() => mockService.deleteWorkspace('w1'))
          .thenAnswer((_) async => const Right(true));

      await Future.delayed(Duration.zero); // Wait for constructor fetch
      
      final result = await notifier.deleteWorkspace('w1');

      expect(result, true);
      expect(notifier.state.workspaces, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('should set error on delete failure', () async {
      when(() => mockService.deleteWorkspace('w1'))
          .thenAnswer((_) async => const Left('Delete Error'));

      await Future.delayed(Duration.zero); // Wait for constructor fetch
      
      final result = await notifier.deleteWorkspace('w1');

      expect(result, false);
      expect(notifier.state.error, 'Delete Error');
      expect(notifier.state.isLoading, false);
    });
  });
}
