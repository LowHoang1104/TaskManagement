class AttachmentEntity {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final String uploadedBy;
  final DateTime createdAt;

  const AttachmentEntity({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  AttachmentEntity copyWith({
    String? id,
    String? taskId,
    String? fileName,
    String? fileUrl,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AttachmentEntity(id: $id, fileName: $fileName, taskId: $taskId)';
}
