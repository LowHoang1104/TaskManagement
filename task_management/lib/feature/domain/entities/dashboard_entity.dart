class DashboardEntity {
  final int totalTasksDone; // all-time completed
  final int tasksDoneThisWeek; // completed since Monday
  final int totalTasksOngoing;
  final int tasksToDo;
  final int tasksInProgress;
  final int tasksReview;

  DashboardEntity({
    required this.totalTasksDone,
    required this.tasksDoneThisWeek,
    required this.totalTasksOngoing,
    required this.tasksToDo,
    required this.tasksInProgress,
    required this.tasksReview,
  });

  factory DashboardEntity.fromJson(Map<String, dynamic> json) {
    return DashboardEntity(
      totalTasksDone: json['totalTasksDone'] ?? 0,
      tasksDoneThisWeek: json['tasksDoneThisWeek'] ?? 0,
      totalTasksOngoing: json['totalTasksOngoing'] ?? 0,
      tasksToDo: json['tasksToDo'] ?? 0,
      tasksInProgress: json['tasksInProgress'] ?? 0,
      tasksReview: json['tasksReview'] ?? 0,
    );
  }

  DashboardEntity copyWith({
    int? totalTasksDone,
    int? tasksDoneThisWeek,
    int? totalTasksOngoing,
    int? tasksToDo,
    int? tasksInProgress,
    int? tasksReview,
  }) {
    return DashboardEntity(
      totalTasksDone: totalTasksDone ?? this.totalTasksDone,
      tasksDoneThisWeek: tasksDoneThisWeek ?? this.tasksDoneThisWeek,
      totalTasksOngoing: totalTasksOngoing ?? this.totalTasksOngoing,
      tasksToDo: tasksToDo ?? this.tasksToDo,
      tasksInProgress: tasksInProgress ?? this.tasksInProgress,
      tasksReview: tasksReview ?? this.tasksReview,
    );
  }
}
