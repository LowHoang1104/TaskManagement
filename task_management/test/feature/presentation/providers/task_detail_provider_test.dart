import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/application/i_services/i_comment_service.dart';
import 'package:task_management/feature/application/i_services/i_attachment_service.dart';
import 'package:task_management/feature/domain/entities/task_entity.dart';
import 'package:task_management/feature/domain/entities/comment_entity.dart';
import 'package:task_management/feature/domain/entities/enums.dart';
import 'package:task_management/feature/presentation/providers/task_detail_provider.dart';

class MockTaskService extends Mock implements ITaskService {}
class MockCommentService extends Mock implements ICommentService {}
class MockAttachmentService extends Mock implements IAttachmentService {}

void main() {
  late TaskDetailNotifier notifier;
  late MockTaskService mockTaskService;
  late MockCommentService mockCommentService;
  late MockAttachmentService mockAttachmentService;

  const tProjectId = 'p1';
  const tTaskId = 't1';

  final tTask = TaskEntity(
    id: tTaskId,
    projectId: tProjectId,
    title: 'Test Task',
    description: 'Desc',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    assigneeId: 'u1',
    reporterId: 'u2',
    order: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    dependencies: const [],
  );

  setUp(() {
    mockTaskService = MockTaskService();
    mockCommentService = MockCommentService();
    mockAttachmentService = MockAttachmentService();

    // The constructor calls _loadData which fetches comments and attachments
    when(() => mockCommentService.getComments(tTaskId))
        .thenAnswer((_) async => const Right([]));
    when(() => mockAttachmentService.getAttachments(tTaskId))
        .thenAnswer((_) async => const Right([]));

    notifier = TaskDetailNotifier(
      tProjectId,
      tTaskId,
      tTask,
      mockTaskService,
      mockCommentService,
      mockAttachmentService,
    );
  });

  group('TaskDetailNotifier - Initialization / loadData', () {
    test('should initialize with task and fetch comments/attachments', () async {
      await Future.delayed(Duration.zero);

      expect(notifier.state.task.id, tTaskId);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.comments, isEmpty);
      expect(notifier.state.attachments, isEmpty);
    });
  });

  group('TaskDetailNotifier - updateTask', () {
    test('should optimistically update task and keep on success', () async {
      final updatedTask = tTask.copyWith(title: 'New Title');
      when(() => mockTaskService.updateTask(tProjectId, tTaskId, 'New Title', 'Desc', TaskPriority.medium))
          .thenAnswer((_) async => Right(updatedTask));

      await Future.delayed(Duration.zero);
      await notifier.updateTask(updatedTask);

      expect(notifier.state.task.title, 'New Title');
      expect(notifier.state.error, null);
    });

    test('should revert on update failure', () async {
      final updatedTask = tTask.copyWith(title: 'New Title');
      when(() => mockTaskService.updateTask(tProjectId, tTaskId, 'New Title', 'Desc', TaskPriority.medium))
          .thenAnswer((_) async => const Left('Update Error'));

      await Future.delayed(Duration.zero);
      await notifier.updateTask(updatedTask);

      // Should revert back to old title
      expect(notifier.state.task.title, 'Test Task');
      expect(notifier.state.error, 'Update Error');
    });
  });

  group('TaskDetailNotifier - addComment', () {
    final tComment = CommentEntity(
      id: 'c1',
      taskId: tTaskId,
      userId: 'u1',
      content: 'New Comment',
      createdAt: DateTime.now(),
      userFullName: 'Test User',
    );

    test('should prepend comment to list on success', () async {
      when(() => mockCommentService.createComment(tTaskId, 'New Comment'))
          .thenAnswer((_) async => Right(tComment));

      await Future.delayed(Duration.zero);
      await notifier.addComment('New Comment');

      expect(notifier.state.comments.length, 1);
      expect(notifier.state.comments.first.id, 'c1');
    });

    test('should set error on failure', () async {
      when(() => mockCommentService.createComment(tTaskId, 'New Comment'))
          .thenAnswer((_) async => const Left('Comment Error'));

      await Future.delayed(Duration.zero);
      await notifier.addComment('New Comment');

      expect(notifier.state.comments, isEmpty);
      expect(notifier.state.error, 'Comment Error');
    });
  });
}
