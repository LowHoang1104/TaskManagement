class CommentEntity {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String userFullName;
  final String? userAvatarUrl;

  const CommentEntity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.userFullName,
    this.userAvatarUrl,
  });

  CommentEntity copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? content,
    DateTime? createdAt,
    String? userFullName,
    String? userAvatarUrl,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      userFullName: userFullName ?? this.userFullName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommentEntity(id: $id, taskId: $taskId, userId: $userId)';
}
