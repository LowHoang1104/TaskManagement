class ActivityLogEntity {
  final String id;
  final String taskId;
  final String userId;
  final String action;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;

  const ActivityLogEntity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  ActivityLogEntity copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? action,
    String? oldValue,
    String? newValue,
    DateTime? createdAt,
  }) {
    return ActivityLogEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ActivityLogEntity(id: $id, action: $action, old: $oldValue, new: $newValue)';
}
