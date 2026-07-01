class WorkspaceEntity {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkspaceEntity({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkspaceEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkspaceEntity(id: $id, name: $name, ownerId: $ownerId)';
}
