class TagEntity {
  final String id;
  final String projectId;
  final String name;
  final String color;

  const TagEntity({
    required this.id,
    required this.projectId,
    required this.name,
    required this.color,
  });

  TagEntity copyWith({
    String? id,
    String? projectId,
    String? name,
    String? color,
  }) {
    return TagEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TagEntity(id: $id, name: $name, color: $color)';
}
