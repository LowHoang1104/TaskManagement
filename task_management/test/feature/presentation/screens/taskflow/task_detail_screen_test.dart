import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/feature/presentation/providers/auth_provider.dart';
import 'package:task_management/feature/presentation/providers/project_members_provider.dart';
import 'package:task_management/feature/presentation/providers/task_detail_provider.dart';
import 'package:task_management/feature/presentation/taskflow/screens/task_detail_screen.dart';
import 'package:task_management/feature/application/i_services/i_auth_service.dart';
import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/application/i_services/i_comment_service.dart';
import 'package:task_management/feature/application/i_services/i_attachment_service.dart';

class MockTaskDetailNotifier extends TaskDetailNotifier with Mock {
  MockTaskDetailNotifier(super.pId, super.tId, super.initialTask, super.taskService, super.commentService, super.attachmentService);
}

class MockAuthService extends Mock implements IAuthService {}
class MockTaskService extends Mock implements ITaskService {}
class MockCommentService extends Mock implements ICommentService {}
class MockAttachmentService extends Mock implements IAttachmentService {}

class MockAuthNotifier extends AuthNotifier with Mock {
  MockAuthNotifier(super.service);
}

class MockProjectMembersNotifier extends ProjectMembersNotifier with Mock {
  MockProjectMembersNotifier(super.projectId);

  @override
  Future<void> fetchMembers() async {}
}

void main() {
  final sampleTask = TaskEntity(
    id: '1',
    projectId: 'p1',
    title: 'Design UI',
    description: 'Create the task details screen',
    status: TaskStatus.todo,
    priority: TaskPriority.high,
    assigneeId: null,
    reporterId: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    deadline: null,
    order: 0,
    relations: [],
  );

  final sampleUser = UserEntity(
    id: 'u1',
    fullName: 'Jane Doe',
    email: 'jane@test.com',
    passwordHash: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createTaskDetailScreen() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          final mock = MockAuthNotifier(MockAuthService());
          mock.state = AuthState(user: sampleUser);
          return mock;
        }),
        projectMembersProvider('p1').overrideWith((ref) {
          final mock = MockProjectMembersNotifier('p1');
          mock.state = const ProjectMembersState(members: []);
          return mock;
        }),
        taskDetailProvider(sampleTask).overrideWith((ref) {
          final mock = MockTaskDetailNotifier('p1', '1', sampleTask, MockTaskService(), MockCommentService(), MockAttachmentService());
          mock.state = TaskDetailState(task: sampleTask, comments: [], attachments: [], isLoading: false);
          return mock;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: TaskDetailScreen(task: sampleTask)),
      ),
    );
  }

  group('TaskDetailScreen Widget Tests', () {
    testWidgets('shows task details', (WidgetTester tester) async {
      await tester.pumpWidget(createTaskDetailScreen());

      expect(find.text('Design UI'), findsOneWidget);
      expect(find.text('Create the task details screen'), findsOneWidget);
      expect(find.text('To Do'), findsWidgets);
    });
  });
}
