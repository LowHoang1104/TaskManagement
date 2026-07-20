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
      // NOT `error ?? this.error`: that made errors sticky forever, so a later
      // successful action would still report the previous failure. Matches the
      // other states (TaskState/WorkspaceState) — omitting `error` clears it.
      error: error,
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
      String? loadError;

      commentsRes.fold((l) => loadError = l, (r) => comments = r);
      attachmentsRes.fold((l) => loadError = l, (r) => attachments = r);

      // Carry the error through the final assignment — copyWith no longer
      // preserves it implicitly.
      state = state.copyWith(
        comments: comments,
        attachments: attachments,
        isLoading: false,
        error: loadError,
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

  /// Moves the task to [status] (To Do → In Progress → Review → Done) and keeps
  /// the board list in sync. Optimistic, reverts on failure.
  Future<void> updateStatus(TaskStatus status, WidgetRef ref) async {
    final oldTask = state.task;
    state = state.copyWith(task: state.task.copyWith(status: status));

    final result = await _taskRepository.updateTaskStatus(
      projectId,
      taskId,
      status,
    );
    result.fold(
      (error) => state = state.copyWith(task: oldTask, error: error),
      (task) {
        state = state.copyWith(task: task);
        ref
            .read(taskNotifierProvider(projectId).notifier)
            .replaceTaskLocally(task);
      },
    );
  }

  /// Owner/Admin only — the API returns 403 for members, and we surface that.
  Future<void> updateDeadline(DateTime deadline, WidgetRef ref) async {
    final oldTask = state.task;
    state = state.copyWith(
      task: state.task.copyWith(deadline: deadline),
      error: null,
    );

    final result = await _taskRepository.updateTaskDeadline(
      projectId,
      taskId,
      deadline,
    );
    result.fold(
      (error) => state = state.copyWith(task: oldTask, error: error),
      (task) {
        state = state.copyWith(task: task);
        ref
            .read(taskNotifierProvider(projectId).notifier)
            .replaceTaskLocally(task);
      },
    );
  }

  Future<void> updateTaskAssignee(String? assigneeId, WidgetRef ref) async {
    final oldTask = state.task;
    final updatedTask = state.task.copyWith(assigneeId: assigneeId);
    state = state.copyWith(task: updatedTask);

    final result = await _taskRepository.updateTaskAssignee(
      state.task.projectId,
      state.task.id,
      assigneeId,
    );
    result.fold(
      (error) => state = state.copyWith(task: oldTask, error: error),
      (task) {
        state = state.copyWith(task: task);
        // Also update the board state
        ref
            .read(taskNotifierProvider(task.projectId).notifier)
            .updateTaskAssigneeLocally(task);
      },
    );
  }

  /// Refetches the project's tasks and refreshes this task's relations
  /// (blocked_by / blocking / related) from the server.
  Future<void> reloadRelations() async {
    final res = await _taskRepository.getTasks(projectId);
    res.fold((_) {}, (tasks) {
      final match = tasks.where((t) => t.id == taskId);
      if (match.isNotEmpty) state = state.copyWith(task: match.first);
    });
  }

  /// Adds a relationship to [otherTaskId]; [kind] ∈ 'blocked_by'|'blocking'|'related'.
  /// Returns an error message on failure, or null on success.
  Future<String?> addRelation(String otherTaskId, String kind) async {
    final res = await _taskRepository.addTaskRelation(
      taskId,
      otherTaskId,
      kind,
    );
    final err = res.fold<String?>((e) => e, (_) => null);
    if (err == null) {
      await reloadRelations();
    } else {
      state = state.copyWith(error: err);
    }
    return err;
  }

  /// Removes a relationship by its dependency id.
  Future<String?> removeRelation(String dependencyId) async {
    final res = await _taskRepository.removeTaskRelation(taskId, dependencyId);
    final err = res.fold<String?>((e) => e, (_) => null);
    if (err == null) {
      await reloadRelations();
    } else {
      state = state.copyWith(error: err);
    }
    return err;
  }

  Future<void> addComment(String content) async {
    if (content.trim().isEmpty) return;

    final result = await _commentRepository.createComment(taskId, content);
    result.fold((error) => state = state.copyWith(error: error), (comment) {
      // Prepend because comments are ordered newest first
      state = state.copyWith(comments: [comment, ...state.comments]);
    });
  }

  /// Cross-platform attachment upload (bytes, so it also works on web).
  Future<bool> uploadAttachmentBytes(String fileName, List<int> bytes) async {
    state = state.copyWith(isLoading: true);
    final result = await _attachmentRepository.uploadAttachmentBytes(
      taskId,
      fileName,
      bytes,
    );
    return result.fold(
      (error) {
        state = state.copyWith(error: error, isLoading: false);
        return false;
      },
      (attachment) {
        state = state.copyWith(
          attachments: [attachment, ...state.attachments],
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Removes an attachment, keeping the list in sync.
  Future<bool> deleteAttachment(String attachmentId) async {
    final result = await _attachmentRepository.deleteAttachment(
      taskId,
      attachmentId,
    );
    return result.fold(
      (error) {
        state = state.copyWith(error: error);
        return false;
      },
      (_) {
        state = state.copyWith(
          attachments: state.attachments
              .where((a) => a.id != attachmentId)
              .toList(),
        );
        return true;
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

final taskDetailProvider =
    StateNotifierProvider.family<
      TaskDetailNotifier,
      TaskDetailState,
      TaskEntity
    >((ref, initialTask) {
      return TaskDetailNotifier(
        initialTask.projectId,
        initialTask.id,
        initialTask,
        sl<ITaskService>(),
        sl<ICommentService>(),
        sl<IAttachmentService>(),
      );
    });
