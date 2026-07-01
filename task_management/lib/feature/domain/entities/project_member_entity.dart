import 'enums.dart';

class ProjectMemberEntity {
  final String projectId;
  final String userId;
  final ProjectRole role;
  final DateTime joinedAt;

  const ProjectMemberEntity({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  ProjectMemberEntity copyWith({
    String? projectId,
    String? userId,
    ProjectRole? role,
    DateTime? joinedAt,
  }) {
    return ProjectMemberEntity(
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberEntity &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          userId == other.userId;

  @override
  int get hashCode => projectId.hashCode ^ userId.hashCode;

  @override
  String toString() =>
      'ProjectMemberEntity(projectId: $projectId, userId: $userId, role: $role)';
}
