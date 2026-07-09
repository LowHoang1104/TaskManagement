import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/i_services/i_comment_service.dart';
import '../../../core/di/injection_container.dart' as di;

final commentServiceProvider = Provider<ICommentService>((ref) {
  return di.sl<ICommentService>();
});

class CommentState {
  final bool isLoading;
  final String? error;
  final List<dynamic> comments;

  CommentState({
    this.isLoading = false,
    this.error,
    this.comments = const [],
  });

  CommentState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? comments,
  }) {
    return CommentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      comments: comments ?? this.comments,
    );
  }
}

class CommentNotifier extends StateNotifier<CommentState> {
  final ICommentService _service;
  final String taskId;

  CommentNotifier(this._service, this.taskId) : super(CommentState());

  Future<void> fetchComments() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.getComments(taskId);
    state = result.fold(
      (error) => state.copyWith(isLoading: false, error: error),
      (comments) => state.copyWith(isLoading: false, comments: comments),
    );
  }

  Future<void> addComment(String content) async {
    final result = await _service.createComment(taskId, content);
    result.fold(
      (error) => state = state.copyWith(error: error),
      (newComment) => state = state.copyWith(comments: [...state.comments, newComment]),
    );
  }
}

final commentNotifierProvider = StateNotifierProvider.family<CommentNotifier, CommentState, String>((ref, taskId) {
  final notifier = CommentNotifier(ref.watch(commentServiceProvider), taskId);
  notifier.fetchComments();
  return notifier;
});
