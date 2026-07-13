import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:task_management/feature/application/i_services/i_comment_service.dart';
import 'package:task_management/feature/domain/entities/comment_entity.dart';
import 'package:task_management/feature/presentation/providers/comment_provider.dart';

class MockCommentService extends Mock implements ICommentService {}

void main() {
  late CommentNotifier notifier;
  late MockCommentService mockService;
  const tTaskId = 't1';

  final tComment = CommentEntity(
    id: 'c1',
    taskId: tTaskId,
    userId: 'u1',
    content: 'Test content',
    createdAt: DateTime.now(),
    userFullName: 'Test User',
  );

  setUp(() {
    mockService = MockCommentService();
    when(() => mockService.getComments(tTaskId))
        .thenAnswer((_) async => Right([tComment]));

    notifier = CommentNotifier(mockService, tTaskId);
  });

  group('CommentNotifier - fetchComments', () {
    test('should set comments on successful fetch', () async {
      await notifier.fetchComments();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.comments.length, 1);
      expect(notifier.state.error, null);
    });

    test('should set error on fetch failure', () async {
      when(() => mockService.getComments(tTaskId))
          .thenAnswer((_) async => const Left('Fetch Error'));
      notifier = CommentNotifier(mockService, tTaskId);
      await notifier.fetchComments();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Fetch Error');
    });
  });

  group('CommentNotifier - addComment', () {
    test('should add comment to list on success', () async {
      final newComment = CommentEntity(
        id: 'c2',
        taskId: tTaskId,
        userId: 'u1',
        content: 'New',
        createdAt: DateTime.now(),
        userFullName: 'Test User',
      );
      
      when(() => mockService.createComment(tTaskId, 'New'))
          .thenAnswer((_) async => Right(newComment));

      await Future.delayed(Duration.zero);
      await notifier.addComment('New');

      expect(notifier.state.comments.length, 1);
      expect(notifier.state.comments.last.id, 'c2');
    });

    test('should set error on add failure', () async {
      when(() => mockService.createComment(tTaskId, 'New'))
          .thenAnswer((_) async => const Left('Add Error'));

      await Future.delayed(Duration.zero);
      await notifier.addComment('New');

      expect(notifier.state.error, 'Add Error');
    });
  });
}
