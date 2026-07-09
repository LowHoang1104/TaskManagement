class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String? avatarUrl;
  final String? role;
  final String? status;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
    this.role,
    this.status,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? avatarUrl,
    String? role,
    String? status,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, fullName: $fullName, email: $email)';
}
