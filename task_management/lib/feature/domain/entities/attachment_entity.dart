class AttachmentEntity {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String uploadedBy;
  final DateTime createdAt;
  final String uploaderFullName;

  const AttachmentEntity({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
    required this.uploaderFullName,
  });

  AttachmentEntity copyWith({
    String? id,
    String? taskId,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? uploadedBy,
    DateTime? createdAt,
    String? uploaderFullName,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      uploaderFullName: uploaderFullName ?? this.uploaderFullName,
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
