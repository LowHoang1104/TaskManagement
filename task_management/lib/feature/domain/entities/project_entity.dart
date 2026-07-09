class ProjectEntity {
  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String ownerId;
  final int progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectEntity({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.ownerId,
    this.progress = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectEntity copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? description,
    String? ownerId,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProjectEntity(id: $id, workspaceId: $workspaceId, name: $name, ownerId: $ownerId)';
}
