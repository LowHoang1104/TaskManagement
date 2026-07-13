import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection_container.dart';
import '../../domain/entities/entities.dart';
import '../../application/i_services/i_task_service.dart';
import '../../application/i_services/i_comment_service.dart';
import '../../application/i_services/i_attachment_service.dart';
import 'task_provider.dart';

class TaskDetailState {
  final TaskEntity task;
  final List<CommentEntity> comments;
  final List<AttachmentEntity> attachments;
  final bool isLoading;
  final String? error;

  const TaskDetailState({
    required this.task,
    this.comments = const [],
    this.attachments = const [],
    this.isLoading = false,
    this.error,
  });

  TaskDetailState copyWith({
    TaskEntity? task,
    List<CommentEntity>? comments,
    List<AttachmentEntity>? attachments,
    bool? isLoading,
    String? error,
  }) {
    return TaskDetailState(
      task: task ?? this.task,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final ITaskService _taskRepository;
  final ICommentService _commentRepository;
  final IAttachmentService _attachmentRepository;
  final String projectId;
  final String taskId;

  TaskDetailNotifier(
    this.projectId,
    this.taskId,
    TaskEntity initialTask,
    this._taskRepository,
    this._commentRepository,
    this._attachmentRepository,
  ) : super(TaskDetailState(task: initialTask, isLoading: true)) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final commentsRes = await _commentRepository.getComments(taskId);
      final attachmentsRes = await _attachmentRepository.getAttachments(taskId);

      List<CommentEntity> comments = [];
      List<AttachmentEntity> attachments = [];

      commentsRes.fold(
        (l) => state = state.copyWith(error: l),
        (r) => comments = r,
      );

      attachmentsRes.fold(
        (l) => state = state.copyWith(error: l),
        (r) => attachments = r,
      );

      state = state.copyWith(
        comments: comments,
        attachments: attachments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateTask(TaskEntity updatedTask) async {
    // Optimistic update
    final oldTask = state.task;
    state = state.copyWith(task: updatedTask);
    
    final result = await _taskRepository.updateTask(
      updatedTask.projectId,
      updatedTask.id,
      updatedTask.title,
      updatedTask.description ?? '',
      updatedTask.priority,
    );

    result.fold(
      (error) {
        // Revert on error
        state = state.copyWith(task: oldTask, error: error);
      },
      (successTask) {
        state = state.copyWith(task: successTask);
      },
    );
  }

  Future<void> updateTaskAssignee(String? assigneeId, WidgetRef ref) async {
    final oldTask = state.task;
    final updatedTask = state.task.copyWith(assigneeId: assigneeId);
    state = state.copyWith(task: updatedTask);

    final result = await _taskRepository.updateTaskAssignee(state.task.projectId, state.task.id, assigneeId);
    result.fold(
      (error) => state = state.copyWith(task: oldTask, error: error),
      (task) {
        state = state.copyWith(task: task);
        // Also update the board state
        ref.read(taskNotifierProvider(task.projectId).notifier).updateTaskAssigneeLocally(task);
      },
    );
  }

  Future<void> addComment(String content) async {
    if (content.trim().isEmpty) return;

    final result = await _commentRepository.createComment(taskId, content);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (comment) {
        // Prepend because comments are ordered newest first
        state = state.copyWith(comments: [comment, ...state.comments]);
      },
    );
  }

  Future<void> uploadAttachment(File file) async {
    state = state.copyWith(isLoading: true);
    final result = await _attachmentRepository.uploadAttachment(taskId, file);
    result.fold(
      (error) => state = state.copyWith(error: error, isLoading: false),
      (attachment) {
        state = state.copyWith(
          attachments: [attachment, ...state.attachments],
          isLoading: false,
        );
      },
    );
  }
}

final taskDetailProvider = StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, TaskEntity>((ref, initialTask) {
  return TaskDetailNotifier(
    initialTask.projectId,
    initialTask.id,
    initialTask,
    sl<ITaskService>(),
    sl<ICommentService>(),
    sl<IAttachmentService>(),
  );
});
