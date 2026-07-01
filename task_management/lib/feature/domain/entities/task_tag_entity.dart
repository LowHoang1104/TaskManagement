class TaskTagEntity {
  final String taskId;
  final String tagId;

  const TaskTagEntity({
    required this.taskId,
    required this.tagId,
  });

  TaskTagEntity copyWith({
    String? taskId,
    String? tagId,
  }) {
    return TaskTagEntity(
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTagEntity &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          tagId == other.tagId;

  @override
  int get hashCode => taskId.hashCode ^ tagId.hashCode;

  @override
  String toString() => 'TaskTagEntity(taskId: $taskId, tagId: $tagId)';
}
