import 'package:equatable/equatable.dart';
import 'enums.dart';

/// How this task relates to another one (intuitive model, à la Jira/Linear):
/// - [blockedBy]: this task waits for the other one to finish.
/// - [blocking]: this task must finish before the other one.
/// - [related]: linked, but no ordering is enforced.
enum TaskRelationKind { blockedBy, blocking, related }

/// A single relationship of a task, seen from that task's point of view.
class TaskRelationEntity extends Equatable {
  final String id; // dependency row id (used to remove it)
  final TaskRelationKind kind;
  final String taskId; // the other task
  final String taskTitle;
  final TaskStatus taskStatus; // status of the other task

  const TaskRelationEntity({
    required this.id,
    required this.kind,
    required this.taskId,
    required this.taskTitle,
    required this.taskStatus,
  });

  bool get isDone => taskStatus == TaskStatus.done;

  factory TaskRelationEntity.fromJson(Map<String, dynamic> json) {
    return TaskRelationEntity(
      id: json['id']?.toString() ?? '',
      kind: _kindFrom(json['kind']?.toString()),
      taskId: json['taskId']?.toString() ?? '',
      taskTitle: json['taskTitle']?.toString() ?? '',
      taskStatus: TaskStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            json['taskStatus']?.toString().toLowerCase(),
        orElse: () => TaskStatus.todo,
      ),
    );
  }

  static TaskRelationKind _kindFrom(String? raw) {
    switch (raw) {
      case 'blocking':
        return TaskRelationKind.blocking;
      case 'related':
        return TaskRelationKind.related;
      case 'blocked_by':
      default:
        return TaskRelationKind.blockedBy;
    }
  }

  /// The wire value the API expects for a relation kind.
  static String kindToApi(TaskRelationKind kind) {
    switch (kind) {
      case TaskRelationKind.blocking:
        return 'blocking';
      case TaskRelationKind.related:
        return 'related';
      case TaskRelationKind.blockedBy:
        return 'blocked_by';
    }
  }

  @override
  List<Object?> get props => [id, kind, taskId, taskTitle, taskStatus];
}
