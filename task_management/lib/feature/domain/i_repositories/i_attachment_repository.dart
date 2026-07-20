import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/attachment_entity.dart';

abstract class IAttachmentRepository {
  Future<Either<String, List<AttachmentEntity>>> getAttachments(String taskId);
  Future<Either<String, AttachmentEntity>> uploadAttachment(String taskId, File file);

  /// Platform-agnostic upload (works on web too, where `dart:io File` is
  /// unavailable) — mirrors how avatar upload already works.
  Future<Either<String, AttachmentEntity>> uploadAttachmentBytes(
      String taskId, String fileName, List<int> bytes);

  Future<Either<String, bool>> deleteAttachment(String taskId, String attachmentId);
}
