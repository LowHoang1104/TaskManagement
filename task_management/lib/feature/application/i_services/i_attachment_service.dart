import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../domain/entities/attachment_entity.dart';

abstract class IAttachmentService {
  Future<Either<String, List<AttachmentEntity>>> getAttachments(String taskId);
  Future<Either<String, AttachmentEntity>> uploadAttachment(String taskId, File file);
  Future<Either<String, AttachmentEntity>> uploadAttachmentBytes(
      String taskId, String fileName, List<int> bytes);
  Future<Either<String, bool>> deleteAttachment(String taskId, String attachmentId);
}
