import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/attachment_entity.dart';

abstract class IAttachmentRepository {
  Future<Either<String, List<AttachmentEntity>>> getAttachments(String taskId);
  Future<Either<String, AttachmentEntity>> uploadAttachment(String taskId, File file);
}
