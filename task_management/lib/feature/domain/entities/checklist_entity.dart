class ChecklistEntity {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;

  const ChecklistEntity({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
  });

  ChecklistEntity copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
  }) {
    return ChecklistEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChecklistEntity(id: $id, title: $title, isCompleted: $isCompleted)';
}
