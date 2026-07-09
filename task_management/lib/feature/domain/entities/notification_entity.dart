class NotificationEntity {
  final String id;
  final String userId;
  final String type;
  final String message;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'],
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      relatedId: json['relatedId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString().endsWith('Z') 
              ? json['createdAt'] 
              : '${json['createdAt']}Z').toLocal() 
          : DateTime.now(),
    );
  }

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    bool? isRead,
    String? relatedId,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationEntity(id: $id, type: $type, isRead: $isRead)';
}
