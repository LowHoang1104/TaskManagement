class DashboardEntity {
  final int totalTasksDone;
  final int totalTasksOngoing;
  final int tasksToDo;
  final int tasksInProgress;
  final int tasksReview;

  DashboardEntity({
    required this.totalTasksDone,
    required this.totalTasksOngoing,
    required this.tasksToDo,
    required this.tasksInProgress,
    required this.tasksReview,
  });

  factory DashboardEntity.fromJson(Map<String, dynamic> json) {
    return DashboardEntity(
      totalTasksDone: json['totalTasksDone'] ?? 0,
      totalTasksOngoing: json['totalTasksOngoing'] ?? 0,
      tasksToDo: json['tasksToDo'] ?? 0,
      tasksInProgress: json['tasksInProgress'] ?? 0,
      tasksReview: json['tasksReview'] ?? 0,
    );
  }

  DashboardEntity copyWith({
    int? totalTasksDone,
    int? totalTasksOngoing,
    int? tasksToDo,
    int? tasksInProgress,
    int? tasksReview,
  }) {
    return DashboardEntity(
      totalTasksDone: totalTasksDone ?? this.totalTasksDone,
      totalTasksOngoing: totalTasksOngoing ?? this.totalTasksOngoing,
      tasksToDo: tasksToDo ?? this.tasksToDo,
      tasksInProgress: tasksInProgress ?? this.tasksInProgress,
      tasksReview: tasksReview ?? this.tasksReview,
    );
  }
}
