import 'package:equatable/equatable.dart';
import 'enums.dart';
import 'task_relation_entity.dart';

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
  final List<TaskRelationEntity> relations;

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
    this.relations = const [],
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
    List<TaskRelationEntity>? relations,
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
      relations: relations ?? this.relations,
    );
  }

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: TaskStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['status'] as String?)?.toLowerCase(),
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['priority'] as String?)?.toLowerCase(),
        orElse: () => TaskPriority.medium,
      ),
      order: json['order'] ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      assigneeId: json['assigneeId'],
      reporterId: json['reporterId'] ?? '',
      assigneeName: json['assigneeName'],
      reporterName: json['reporterName'],
      reviewerId: json['reviewerId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      relations: json['relations'] != null
          ? (json['relations'] as List)
                .map(
                  (e) => TaskRelationEntity.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
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
    };
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    status,
    priority,
    order,
    deadline,
    assigneeId,
    reporterId,
    assigneeName,
    reporterName,
    reviewerId,
    createdAt,
    updatedAt,
    relations,
  ];
}
