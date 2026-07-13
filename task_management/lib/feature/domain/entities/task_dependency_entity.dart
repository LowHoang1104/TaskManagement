class TaskDependencyEntity {
  final String id;
  final String predecessorTaskId;
  final String successorTaskId;
  final String dependencyType;
  final String predecessorTaskTitle;

  const TaskDependencyEntity({
    required this.id,
    required this.predecessorTaskId,
    required this.successorTaskId,
    required this.dependencyType,
    required this.predecessorTaskTitle,
  });

  factory TaskDependencyEntity.fromJson(Map<String, dynamic> json) {
    return TaskDependencyEntity(
      id: json['id'] ?? '',
      predecessorTaskId: json['predecessorTaskId'] ?? '',
      successorTaskId: json['successorTaskId'] ?? '',
      dependencyType: json['dependencyType'] ?? 'FS',
      predecessorTaskTitle: json['predecessorTaskTitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'predecessorTaskId': predecessorTaskId,
      'successorTaskId': successorTaskId,
      'dependencyType': dependencyType,
      'predecessorTaskTitle': predecessorTaskTitle,
    };
  }
}
