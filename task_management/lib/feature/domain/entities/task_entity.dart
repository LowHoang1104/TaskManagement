import 'package:equatable/equatable.dart';
import 'enums.dart';
import 'task_dependency_entity.dart';

class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int order;
  final DateTime? deadline;
  final String? assigneeId;
  final String reporterId;
  final String? assigneeName;
  final String? reporterName;
  final String? reviewerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskDependencyEntity> dependencies;

  const TaskEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.order,
    this.deadline,
    this.assigneeId,
    required this.reporterId,
    this.assigneeName,
    this.reporterName,
    this.reviewerId,
    required this.createdAt,
    required this.updatedAt,
    this.dependencies = const [],
  });

  TaskEntity copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    int? order,
    DateTime? deadline,
    String? assigneeId,
    String? reporterId,
    String? assigneeName,
    String? reporterName,
    String? reviewerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskDependencyEntity>? dependencies,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      order: order ?? this.order,
      deadline: deadline ?? this.deadline,
      assigneeId: assigneeId ?? this.assigneeId,
      reporterId: reporterId ?? this.reporterId,
      assigneeName: assigneeName ?? this.assigneeName,
      reporterName: reporterName ?? this.reporterName,
      reviewerId: reviewerId ?? this.reviewerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['status'] as String?)?.toLowerCase(),
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['priority'] as String?)?.toLowerCase(),
        orElse: () => TaskPriority.medium,
      ),
      order: json['order'] ?? 0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      assigneeId: json['assigneeId'],
      reporterId: json['reporterId'] ?? '',
      assigneeName: json['assigneeName'],
      reporterName: json['reporterName'],
      reviewerId: json['reviewerId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      dependencies: json['dependencies'] != null ? (json['dependencies'] as List).map((e) => TaskDependencyEntity.fromJson(e)).toList() : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority.name,
      'order': order,
      'deadline': deadline?.toIso8601String(),
      'assigneeId': assigneeId,
      'reporterId': reporterId,
      'assigneeName': assigneeName,
      'reporterName': reporterName,
      'reviewerId': reviewerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dependencies': dependencies.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, projectId, title, description, status, priority, order, deadline, assigneeId, reporterId, assigneeName, reporterName, reviewerId, createdAt, updatedAt, dependencies];
}
