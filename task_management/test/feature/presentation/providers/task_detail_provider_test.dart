import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:task_management/feature/application/i_services/i_task_service.dart';
import 'package:task_management/feature/application/i_services/i_comment_service.dart';
import 'package:task_management/feature/application/i_services/i_attachment_service.dart';
import 'package:task_management/feature/domain/entities/entities.dart';
import 'package:task_management/feature/presentation/providers/task_detail_provider.dart';

class MockTaskService extends Mock implements ITaskService {}
class MockCommentService extends Mock implements ICommentService {}
class MockAttachmentService extends Mock implements IAttachmentService {}

class FakeFile extends Fake implements File {}

void main() {
  late MockTaskService mockTaskService;
  late MockCommentService mockCommentService;
  late MockAttachmentService mockAttachmentService;
  late TaskDetailNotifier notifier;

  final initialTask = TaskEntity(
    id: '1',
    projectId: 'p1',
    title: 'Test Task',
    description: '',
    status: TaskStatus.todo,
    priority: TaskPriority.high,
    assigneeId: null,
    reporterId: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    order: 0,
    relations: [],
  );

  final sampleComment = CommentEntity(
    id: 'c1',
    taskId: '1',
    userId: 'u1',
    content: 'First comment',
    createdAt: DateTime.now(),
    userFullName: 'John Doe',
    userAvatarUrl: null,
  );

  final sampleAttachment = AttachmentEntity(
    id: 'a1',
    taskId: '1',
    fileName: 'test.png',
    fileUrl: 'url',
    fileSize: 100,
    uploadedBy: 'u1',
    createdAt: DateTime.now(),
    uploaderFullName: 'John Doe',
  );

  setUp(() {
    mockTaskService = MockTaskService();
    mockCommentService = MockCommentService();
    mockAttachmentService = MockAttachmentService();

    when(() => mockCommentService.getComments('1')).thenAnswer((_) async => const Right([]));
    when(() => mockAttachmentService.getAttachments('1')).thenAnswer((_) async => const Right([]));

    notifier = TaskDetailNotifier(
      'p1',
      '1',
      initialTask,
      mockTaskService,
      mockCommentService,
      mockAttachmentService,
    );
  });

  group('loadData', () {
    test('fetches comments and attachments on init', () async {
      // Allow the constructor's _loadData to finish
      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.comments.isEmpty, true);
      expect(notifier.state.attachments.isEmpty, true);
      verify(() => mockCommentService.getComments('1')).called(1);
      verify(() => mockAttachmentService.getAttachments('1')).called(1);
    });
  });

  group('addComment', () {
    test('adds comment to state on success', () async {
      when(() => mockCommentService.createComment('1', 'New comment')).thenAnswer((_) async => Right(sampleComment));

      await notifier.addComment('New comment');

      expect(notifier.state.comments.contains(sampleComment), true);
      expect(notifier.state.error, isNull);
    });

    test('does nothing if comment is empty', () async {
      await notifier.addComment('   ');
      verifyNever(() => mockCommentService.createComment(any(), any()));
    });
  });

  group('attachments', () {
    test('uploadAttachmentBytes adds to state on success', () async {
      when(() => mockAttachmentService.uploadAttachmentBytes('1', 'test.png', [1, 2, 3]))
          .thenAnswer((_) async => Right(sampleAttachment));

      final success = await notifier.uploadAttachmentBytes('test.png', [1, 2, 3]);

      expect(success, true);
      expect(notifier.state.attachments.contains(sampleAttachment), true);
    });

    test('deleteAttachment removes from state on success', () async {
      notifier.state = notifier.state.copyWith(attachments: [sampleAttachment]);
      when(() => mockAttachmentService.deleteAttachment('1', 'a1')).thenAnswer((_) async => const Right(true));

      final success = await notifier.deleteAttachment('a1');

      expect(success, true);
      expect(notifier.state.attachments.isEmpty, true);
    });
  });
}
