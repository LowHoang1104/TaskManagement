import 'enums.dart';

class WorkspaceMemberEntity {
  final String workspaceId;
  final String userId;
  final WorkspaceRole role;
  final DateTime joinedAt;

  const WorkspaceMemberEntity({
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  WorkspaceMemberEntity copyWith({
    String? workspaceId,
    String? userId,
    WorkspaceRole? role,
    DateTime? joinedAt,
  }) {
    return WorkspaceMemberEntity(
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceMemberEntity &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          userId == other.userId;

  @override
  int get hashCode => workspaceId.hashCode ^ userId.hashCode;

  @override
  String toString() =>
      'WorkspaceMemberEntity(workspaceId: $workspaceId, userId: $userId, role: $role)';
}
